// Validate the HTML and JS without a browser, renderer or respring attempt.
import fs from 'node:fs';
import vm from 'node:vm';
const source = fs.readFileSync(new URL('../GestaltX/NeoSpringView.swift', import.meta.url), 'utf8');
const html = source.split('private static let document = #"""')[1].split('"""#')[0];
const outer = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const frame = {srcdoc: ''};
vm.runInNewContext(outer, {document: {getElementById: () => frame}});
const inner = frame.srcdoc.match(/<script>([\s\S]*?)<\/script>/);
if (!inner) throw new Error('The nested script closing tag is invalid');
let length = 0;
const element = () => ({style: {}, appendChild() {}});
vm.runInNewContext(inner[1], {
  document: {createElement: element, body: {appendChild() {}}},
  setInterval(callback) { callback(); },
  navigator: {share() { return Promise.resolve(); }},
  Uint8Array,
  crypto: {getRandomValues(bytes) { length = bytes.byteLength; if (length > 65536) throw new Error('Web Crypto quota exceeded'); }},
});
if (length !== 65536) throw new Error('Unexpected random-data request');
console.log('PASS: NeoSpring nested HTML closes correctly, JavaScript parses, and the Web Crypto request respects the 65,536-byte limit. No rendering or respring was performed.');
