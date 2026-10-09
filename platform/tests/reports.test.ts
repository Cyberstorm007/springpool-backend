import {test} from 'node:test';
import assert from 'node:assert/strict';
import {csvCell,toCsv} from '../lib/operations/reports';
test('CSV exports escape spreadsheet formulas, quotes and multiline data',()=>{
 assert.equal(csvCell('=SUM(A1:A2)'),`"'=SUM(A1:A2)"`);
 assert.equal(csvCell('  @malicious'),`"'  @malicious"`);
 assert.equal(csvCell('a,"b"\nc'),'"a,""b""\nc"');
 assert.equal(toCsv(['name','amount'],[{name:'Sample',amount:42}]),'\uFEFF"name","amount"\r\n"Sample","42"');
});
