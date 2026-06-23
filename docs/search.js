const $q       = document.getElementById('q');
const $results = document.getElementById('results');
const $empty   = document.getElementById('empty');
const $meta    = document.getElementById('meta');
const $tpl     = document.getElementById('card');

let entries = [];

async function load() {
  const r = await fetch('commands.json');
  entries = await r.json();
  render(entries);
  $meta.textContent = `${entries.length} commands`;
}

function highlight(text, q) {
  if (!q || !text) return text || '';
  const i = text.toLowerCase().indexOf(q);
  if (i < 0) return text;
  return text.slice(0, i) + '<mark>' + text.slice(i, i + q.length) + '</mark>' + text.slice(i + q.length);
}

function render(list, q = '') {
  $results.innerHTML = '';
  if (list.length === 0) {
    $empty.hidden = false;
    return;
  }
  $empty.hidden = true;
  const frag = document.createDocumentFragment();
  list.forEach((e, idx) => {
    const node = $tpl.content.firstElementChild.cloneNode(true);
    if (q && idx === 0) node.classList.add('featured');
    node.querySelector('.name').innerHTML   = highlight(e.name,   q);
    node.querySelector('.cat').textContent  = e.category.toLowerCase();
    node.querySelector('.syntax').innerHTML = highlight(e.syntax, q);
    node.querySelector('.desc').innerHTML   = highlight(e.desc,   q);
    if (e.example) {
      const ex = node.querySelector('.ex');
      ex.textContent = e.example;
      ex.hidden = false;
    }
    frag.appendChild(node);
  });
  $results.appendChild(frag);
}

function score(e, q) {
  const n = e.name.toLowerCase();
  if (n === q)            return 1000;
  if (n.startsWith(q))    return  500;
  if (n.includes(q))      return  200;
  if ((e.syntax  || '').toLowerCase().includes(q)) return 50;
  if ((e.desc    || '').toLowerCase().includes(q)) return 10;
  if ((e.example || '').toLowerCase().includes(q)) return  5;
  return 0;
}

function filter() {
  const q = $q.value.trim().toLowerCase();
  if (!q) {
    render(entries);
    $meta.textContent = `${entries.length} commands`;
    return;
  }
  const ranked = entries
    .map(e => ({ e, s: score(e, q) }))
    .filter(x => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .map(x => x.e);
  render(ranked, q);
  $meta.textContent = `${ranked.length} / ${entries.length}`;
}

$q.addEventListener('input', filter);
load();
