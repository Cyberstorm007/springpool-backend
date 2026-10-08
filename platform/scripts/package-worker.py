"""Produce a Cloudflare API manifest from the verified Vinext build (no secrets)."""
import hashlib, json
from pathlib import Path
root=Path('.cloudflare/output/v0/workers/default')
assets=root/'assets'
manifest={}
for p in assets.rglob('*'):
    if p.is_file() and p.name not in ('_headers','_redirects'):
        data=p.read_bytes()
        manifest['/'+p.relative_to(assets).as_posix()]={'hash':hashlib.sha256(data).hexdigest()[:32],'size':len(data)}
Path('/tmp/springpool-asset-manifest.json').write_text(json.dumps(manifest))
modules=[]
for p in (root/'bundle').rglob('*.js'):
    modules.append({'name':p.relative_to(root/'bundle').as_posix(),'content':p.read_text()})
Path('/tmp/springpool-worker-modules.json').write_text(json.dumps(modules))
print(json.dumps({'assets':len(manifest),'modules':len(modules),'module_bytes':sum(len(m['content']) for m in modules)}))
