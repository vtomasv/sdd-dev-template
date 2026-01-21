/**
 * Mini Kanban Web - JavaScript Application
 * Implementación de un tablero Kanban con drag & drop y persistencia local
 */

// Estado de la aplicación
let tasks = {
    todo: [],
    inprogress: [],
    done: []
};

// Constantes
const STORAGE_KEY = 'mini-kanban-tasks';

// ============================================
// Inicialización
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    loadTasks();
    renderAllTasks();
    console.log('✅ Mini Kanban inicializado');
});

// ============================================
// Persistencia (localStorage)
// ============================================

function loadTasks() {
    try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
            tasks = JSON.parse(stored);
            console.log('📂 Tareas cargadas desde localStorage');
        }
    } catch (error) {
        console.error('Error cargando tareas:', error);
        tasks = { todo: [], inprogress: [], done: [] };
    }
}

function saveTasks() {
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
        console.log('💾 Tareas guardadas');
    } catch (error) {
        console.error('Error guardando tareas:', error);
    }
}

// ============================================
// Gestión de Tareas
// ============================================

function generateId() {
    return 'task-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
}

function addTask(column) {
    const input = document.getElementById(`new-task-${column}`);
    const text = input.value.trim();
    
    // Validación FR9: evitar tareas vacías
    if (!text) {
        input.classList.add('error');
        setTimeout(() => input.classList.remove('error'), 500);
        return;
    }
    
    const task = {
        id: generateId(),
        text: text,
        createdAt: new Date().toISOString()
    };
    
    tasks[column].push(task);
    saveTasks();
    renderColumn(column);
    
    input.value = '';
    input.focus();
    
    console.log(`➕ Tarea agregada a ${column}:`, task.text);
}

function deleteTask(taskId, column) {
    tasks[column] = tasks[column].filter(t => t.id !== taskId);
    saveTasks();
    renderColumn(column);
    console.log(`🗑️ Tarea eliminada: ${taskId}`);
}

function editTask(taskId, column) {
    const taskElement = document.querySelector(`[data-task-id="${taskId}"] .task-text`);
    const task = tasks[column].find(t => t.id === taskId);
    
    if (!taskElement || !task) return;
    
    // Convertir a input editable
    taskElement.contentEditable = true;
    taskElement.classList.add('editing');
    taskElement.focus();
    
    // Seleccionar todo el texto
    const range = document.createRange();
    range.selectNodeContents(taskElement);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    
    // Guardar al perder foco o presionar Enter
    const saveEdit = () => {
        const newText = taskElement.textContent.trim();
        
        if (newText) {
            task.text = newText;
            task.updatedAt = new Date().toISOString();
            saveTasks();
            console.log(`✏️ Tarea editada: ${taskId}`);
        } else {
            taskElement.textContent = task.text;
        }
        
        taskElement.contentEditable = false;
        taskElement.classList.remove('editing');
    };
    
    taskElement.onblur = saveEdit;
    taskElement.onkeydown = (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            taskElement.blur();
        }
        if (e.key === 'Escape') {
            taskElement.textContent = task.text;
            taskElement.blur();
        }
    };
}

function handleKeyPress(event, column) {
    if (event.key === 'Enter') {
        addTask(column);
    }
}

// ============================================
// Drag & Drop
// ============================================

let draggedTask = null;
let sourceColumn = null;

function allowDrop(event) {
    event.preventDefault();
    event.currentTarget.classList.add('drag-over');
}

function drag(event) {
    draggedTask = event.target;
    sourceColumn = event.target.closest('.task-list').id;
    
    event.dataTransfer.setData('text/plain', event.target.dataset.taskId);
    event.dataTransfer.effectAllowed = 'move';
    
    setTimeout(() => {
        event.target.classList.add('dragging');
    }, 0);
}

function drop(event) {
    event.preventDefault();
    const targetColumn = event.currentTarget.id;
    event.currentTarget.classList.remove('drag-over');
    
    if (!draggedTask || !sourceColumn) return;
    
    const taskId = draggedTask.dataset.taskId;
    
    // Encontrar y mover la tarea
    const taskIndex = tasks[sourceColumn].findIndex(t => t.id === taskId);
    if (taskIndex === -1) return;
    
    const [task] = tasks[sourceColumn].splice(taskIndex, 1);
    task.movedAt = new Date().toISOString();
    tasks[targetColumn].push(task);
    
    saveTasks();
    renderColumn(sourceColumn);
    renderColumn(targetColumn);
    
    console.log(`🔄 Tarea movida de ${sourceColumn} a ${targetColumn}`);
    
    draggedTask = null;
    sourceColumn = null;
}

function dragEnd(event) {
    event.target.classList.remove('dragging');
    document.querySelectorAll('.task-list').forEach(list => {
        list.classList.remove('drag-over');
    });
}

function dragLeave(event) {
    event.currentTarget.classList.remove('drag-over');
}

// Agregar eventos de drag leave a las listas
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.task-list').forEach(list => {
        list.addEventListener('dragleave', dragLeave);
    });
});

// ============================================
// Renderizado
// ============================================

function createTaskElement(task, column) {
    const div = document.createElement('div');
    div.className = 'task-card';
    div.draggable = true;
    div.dataset.taskId = task.id;
    
    div.ondragstart = drag;
    div.ondragend = dragEnd;
    
    div.innerHTML = `
        <div class="task-content">
            <span class="task-text">${escapeHtml(task.text)}</span>
            <div class="task-actions">
                <button class="btn-edit" onclick="editTask('${task.id}', '${column}')" title="Editar">✏️</button>
                <button class="btn-delete" onclick="deleteTask('${task.id}', '${column}')" title="Eliminar">🗑️</button>
            </div>
        </div>
    `;
    
    return div;
}

function renderColumn(column) {
    const container = document.getElementById(column);
    container.innerHTML = '';
    
    tasks[column].forEach(task => {
        container.appendChild(createTaskElement(task, column));
    });
    
    // Actualizar contador
    const countElement = document.getElementById(`count-${column}`);
    if (countElement) {
        countElement.textContent = tasks[column].length;
    }
}

function renderAllTasks() {
    renderColumn('todo');
    renderColumn('inprogress');
    renderColumn('done');
}

// ============================================
// Utilidades
// ============================================

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================
// API pública (para testing/debugging)
// ============================================

window.KanbanApp = {
    getTasks: () => ({ ...tasks }),
    clearAll: () => {
        tasks = { todo: [], inprogress: [], done: [] };
        saveTasks();
        renderAllTasks();
        console.log('🧹 Todas las tareas eliminadas');
    },
    exportData: () => JSON.stringify(tasks, null, 2),
    importData: (data) => {
        try {
            tasks = JSON.parse(data);
            saveTasks();
            renderAllTasks();
            console.log('📥 Datos importados');
        } catch (e) {
            console.error('Error importando datos:', e);
        }
    }
};

console.log('🎯 Mini Kanban Web v1.0 - Creado con SDD Template');
console.log('💡 Usa KanbanApp.getTasks() para ver el estado actual');
