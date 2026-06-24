const state = {
  questions: [],
  search: '',
  area: '',
  subject: ''
};

const elements = {
  search: document.querySelector('#search'),
  areaFilter: document.querySelector('#area-filter'),
  subjectFilter: document.querySelector('#subject-filter'),
  count: document.querySelector('#count'),
  catalog: document.querySelector('#catalog'),
  template: document.querySelector('#question-template')
};

async function loadQuestions() {
  try {
    const response = await fetch('data/questoes-demo.json');
    if (!response.ok) {
      throw new Error(`Erro ao carregar dados: ${response.status}`);
    }

    const data = await response.json();
    state.questions = data.questions.filter((question) => question.visibility === 'demo');
    setupFilters();
    render();
  } catch (error) {
    elements.catalog.innerHTML = `
      <article class="question-card">
        <h2>Não foi possível carregar o catálogo</h2>
        <p>${escapeHtml(error.message)}</p>
      </article>
    `;
  }
}

function setupFilters() {
  const areas = uniqueSorted(state.questions.map((question) => question.area));
  const subjects = uniqueSorted(state.questions.map((question) => question.subject));

  fillSelect(elements.areaFilter, areas, 'Todas');
  fillSelect(elements.subjectFilter, subjects, 'Todos');

  elements.search.addEventListener('input', (event) => {
    state.search = event.target.value.trim().toLowerCase();
    render();
  });

  elements.areaFilter.addEventListener('change', (event) => {
    state.area = event.target.value;
    render();
  });

  elements.subjectFilter.addEventListener('change', (event) => {
    state.subject = event.target.value;
    render();
  });
}

function fillSelect(select, values, defaultLabel) {
  select.innerHTML = `<option value="">${defaultLabel}</option>`;
  values.forEach((value) => {
    const option = document.createElement('option');
    option.value = value;
    option.textContent = value;
    select.appendChild(option);
  });
}

function render() {
  const filtered = state.questions.filter(matchesFilters);
  elements.count.textContent = `${filtered.length} de ${state.questions.length} questões demonstrativas`;

  elements.catalog.innerHTML = '';

  if (filtered.length === 0) {
    elements.catalog.innerHTML = `
      <article class="question-card">
        <h2>Nenhuma questão encontrada</h2>
        <p>Experimente remover algum filtro ou alterar o termo de busca.</p>
      </article>
    `;
    return;
  }

  filtered.forEach((question) => {
    elements.catalog.appendChild(renderQuestion(question));
  });

  if (window.MathJax?.typesetPromise) {
    window.MathJax.typesetPromise();
  }
}

function matchesFilters(question) {
  const haystack = [
    question.id,
    question.title,
    question.area,
    question.subject,
    question.level,
    ...(question.tags || [])
  ]
    .join(' ')
    .toLowerCase();

  return (
    (!state.search || haystack.includes(state.search)) &&
    (!state.area || question.area === state.area) &&
    (!state.subject || question.subject === state.subject)
  );
}

function renderQuestion(question) {
  const fragment = elements.template.content.cloneNode(true);
  const card = fragment.querySelector('.question-card');
  const title = fragment.querySelector('h2');
  const id = fragment.querySelector('.question-id');
  const meta = fragment.querySelector('.question-meta');
  const tags = fragment.querySelector('.tags');
  const body = fragment.querySelector('.question-body');
  const solution = fragment.querySelector('.solution-body');

  card.dataset.area = question.area;
  card.dataset.subject = question.subject;
  title.textContent = question.title;
  id.textContent = question.id;
  meta.textContent = `${question.area} · ${question.subject} · ${question.level}`;
  body.innerHTML = question.statementHtml;
  solution.innerHTML = question.solutionHtml;

  (question.tags || []).forEach((tag) => {
    const item = document.createElement('span');
    item.className = 'tag';
    item.textContent = tag;
    tags.appendChild(item);
  });

  return fragment;
}

function uniqueSorted(values) {
  return [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b, 'pt-BR'));
}

function escapeHtml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

loadQuestions();
