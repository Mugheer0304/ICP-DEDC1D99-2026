// All requests go to relative paths ("/api/..." and "/health").
// Nginx (see nginx.conf) proxies these to the backend container,
// so the browser never needs to know the backend's internal address.

const statusEl = document.getElementById('status');
const listEl = document.getElementById('taskList');
const formEl = document.getElementById('taskForm');
const inputEl = document.getElementById('taskInput');

async function checkHealth() {
  try {
    const res = await fetch('/health');
    const data = await res.json();
    statusEl.textContent = `Backend: ${res.ok ? 'Healthy ✅' : 'Unhealthy ⚠️'} | Postgres: ${data.postgres} | Redis: ${data.redis}`;
    statusEl.className = res.ok ? 'ok' : 'bad';
  } catch (err) {
    statusEl.textContent = 'Backend unreachable ❌';
    statusEl.className = 'bad';
  }
}

async function loadTasks() {
  try {
    const res = await fetch('/api/tasks');
    const data = await res.json();
    listEl.innerHTML = '';
    data.tasks.forEach((task) => {
      const li = document.createElement('li');
      li.innerHTML = `<span class="${task.completed ? 'done' : ''}">${task.title}</span>`;
      if (!task.completed) {
        const btn = document.createElement('button');
        btn.textContent = 'Done';
        btn.onclick = () => completeTask(task.id);
        li.appendChild(btn);
      }
      listEl.appendChild(li);
    });
  } catch (err) {
    listEl.innerHTML = '<li>Could not load tasks</li>';
  }
}

async function completeTask(id) {
  await fetch(`/api/tasks/${id}/complete`, { method: 'PATCH' });
  loadTasks();
}

formEl.addEventListener('submit', async (e) => {
  e.preventDefault();
  const title = inputEl.value.trim();
  if (!title) return;
  await fetch('/api/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title }),
  });
  inputEl.value = '';
  loadTasks();
});

checkHealth();
loadTasks();
setInterval(checkHealth, 5000);
