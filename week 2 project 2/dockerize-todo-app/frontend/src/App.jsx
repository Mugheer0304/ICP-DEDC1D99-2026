import React, { useEffect, useState } from "react";

// In the browser, requests go to "/api/...", which Nginx proxies
// to the backend container. The browser never talks to the backend directly.
const API_BASE = "/api/todos";

export default function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  async function fetchTodos() {
    try {
      setLoading(true);
      const res = await fetch(API_BASE);
      if (!res.ok) throw new Error("Failed to load todos");
      const data = await res.json();
      setTodos(data);
      setError("");
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchTodos();
  }, []);

  async function addTodo(e) {
    e.preventDefault();
    if (!title.trim()) return;
    try {
      const res = await fetch(API_BASE, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title }),
      });
      if (!res.ok) throw new Error("Failed to add todo");
      setTitle("");
      fetchTodos();
    } catch (err) {
      setError(err.message);
    }
  }

  async function toggleTodo(id) {
    try {
      await fetch(`${API_BASE}/${id}`, { method: "PATCH" });
      fetchTodos();
    } catch (err) {
      setError(err.message);
    }
  }

  async function deleteTodo(id) {
    try {
      await fetch(`${API_BASE}/${id}`, { method: "DELETE" });
      fetchTodos();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="container">
      <h1>Dockerized Todo App</h1>
      <p className="subtitle">React + Node/Express + PostgreSQL, all in containers</p>

      <form onSubmit={addTodo} className="add-form">
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="What needs to be done?"
        />
        <button type="submit">Add</button>
      </form>

      {error && <p className="error">Error: {error}</p>}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <ul className="todo-list">
          {todos.map((todo) => (
            <li key={todo.id} className={todo.completed ? "completed" : ""}>
              <span onClick={() => toggleTodo(todo.id)}>{todo.title}</span>
              <button onClick={() => deleteTodo(todo.id)}>✕</button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
