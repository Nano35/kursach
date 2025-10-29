
const apiBaseEl = document.getElementById('apiBase');
const listsEl = document.getElementById('lists');
const listNameEl = document.getElementById('listName');

document.getElementById('reload').onclick = loadLists;
document.getElementById('addList').onclick = async () => {
  if (!listNameEl.value.trim()) return;
  await fetch(api('/lists'), {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({name: listNameEl.value.trim()}),
  });
  listNameEl.value = '';
  loadLists();
};

function api(path) {
  return apiBaseEl.value.replace(/\/$/, '') + path;
}

async function loadLists() {
  listsEl.innerHTML = 'Загрузка...';
  const res = await fetch(api('/lists'));
  const data = await res.json();
  listsEl.innerHTML = '';
  data.forEach(renderList);
}

function renderList(list) {
  const tpl = document.getElementById('listTpl');
  const node = tpl.content.firstElementChild.cloneNode(true);
  node.querySelector('.title').textContent = list.name;
  const choicesEl = node.querySelector('.choices');
  const resultEl = node.querySelector('.result');

  node.querySelector('.btn-delete').onclick = async () => {
    if (!confirm('Удалить список?')) return;
    await fetch(api(`/lists/${list.id}`), { method: 'DELETE' });
    loadLists();
  };

  node.querySelector('.btn-add-choice').onclick = async () => {
    const input = node.querySelector('.choiceText');
    const text = input.value.trim();
    if (!text) return;
    await fetch(api(`/lists/${list.id}/choices`), {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({text})
    });
    input.value = '';
    refreshChoices();
  };

  node.querySelector('.btn-pick').onclick = async () => {
    const res = await fetch(api(`/lists/${list.id}/pick`), { method: 'POST' });
    if (res.ok) {
      const item = await res.json();
      resultEl.textContent = '🎯 Выбрано: ' + item.text;
    } else {
      const err = await res.json();
      resultEl.textContent = 'Ошибка: ' + err.detail;
    }
  };

  async function refreshChoices() {
    const res = await fetch(api(`/lists/${list.id}/choices`));
    const items = await res.json();
    choicesEl.innerHTML = '';
    items.forEach(item => {
      const li = document.createElement('li');
      const span = document.createElement('span');
      span.textContent = item.text;
      const btn = document.createElement('button');
      btn.className = 'del';
      btn.textContent = 'Удалить';
      btn.onclick = async () => {
        await fetch(api(`/choices/${item.id}`), { method: 'DELETE' });
        refreshChoices();
      };
      li.appendChild(span);
      li.appendChild(btn);
      choicesEl.appendChild(li);
    });
  }

  listsEl.appendChild(node);
  refreshChoices();
}

loadLists();
