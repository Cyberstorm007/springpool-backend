"""Upload only the build assets requested by a short-lived Cloudflare upload session.
Read the session JSON from stdin; never persist its credential to disk.
"""
import sys, json, base64, mimetypes, urllib.request, uuid
from pathlib import Path

session = json.loads(sys.stdin.readline())
manifest = json.loads(Path('/tmp/springpool-asset-manifest.json').read_text())
paths = {v['hash']: p for p, v in manifest.items()}
completion = None
for bucket in session['buckets']:
    boundary = 'sp' + uuid.uuid4().hex
    parts = []
    for digest in bucket:
        path = paths[digest]
        data = Path('.cloudflare/output/v0/workers/default/assets' + path).read_bytes()
        mime = mimetypes.guess_type(path)[0] or 'application/octet-stream'
        header = f'--{boundary}\r\nContent-Disposition: form-data; name="{digest}"; filename="{digest}"\r\nContent-Type: {mime}\r\n\r\n'
        parts.append(header.encode() + base64.b64encode(data) + b'\r\n')
    body = b''.join(parts) + f'--{boundary}--\r\n'.encode()
    request = urllib.request.Request(
        'https://api.cloudflare.com/client/v4/accounts/1e79742f585739c8e7f4085318149f5f/workers/assets/upload?base64=true',
        data=body, method='POST', headers={'Authorization': 'Bearer ' + session['jwt'], 'Content-Type': 'multipart/form-data; boundary=' + boundary})
    with urllib.request.urlopen(request, timeout=60) as response:
        result = json.load(response)
    if not result.get('success'):
        raise RuntimeError('Asset upload failed')
    completion = result.get('result', {}).get('jwt') or completion
print(json.dumps({'jwt': completion or session['jwt']}))
