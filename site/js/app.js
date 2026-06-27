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

  filtered.forEach((question, index) => {
    elements.catalog.appendChild(renderQuestion(question, index));
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

function renderQuestion(question, index) {
  const fragment = elements.template.content.cloneNode(true);
  const card = fragment.querySelector('.question-card');
  const title = fragment.querySelector('h2');
  const id = fragment.querySelector('.question-id');
  const meta = fragment.querySelector('.question-meta');
  const tags = fragment.querySelector('.tags');
  const body = fragment.querySelector('.question-body');
  const solution = fragment.querySelector('.solution-body');
  const moodlePreview = fragment.querySelector('.moodle-preview');

  card.dataset.area = question.area;
  card.dataset.subject = question.subject;
  title.textContent = question.title;
  id.textContent = question.id;
  meta.textContent = `${question.area} · ${question.subject} · ${question.level}`;
  body.innerHTML = question.statementHtml;
  solution.innerHTML = question.solutionHtml;
  moodlePreview.innerHTML = renderMoodlePreview(question, index);

  (question.tags || []).forEach((tag) => {
    const item = document.createElement('span');
    item.className = 'tag';
    item.textContent = tag;
    tags.appendChild(item);
  });

  return fragment;
}

function renderMoodlePreview(question, index) {
  const number = index + 1;

  return `
    <section class="moodle-card moodle-attempt" aria-label="Preview estilo Moodle de ${escapeHtml(question.title)}">
      <div class="moodle-attempt-header">
        <div>
          <span class="moodle-crumb">Página inicial / BancoFisica / Questionário demonstrativo</span>
          <h3>Pré-visualização da questão demonstrativa</h3>
        </div>
        <span class="moodle-pill">Simulação visual</span>
      </div>

      <div class="moodle-attempt-layout">
        <article class="moodle-attempt-main">
          <header class="moodle-question-header">
            <div>
              <p class="moodle-question-title">Questão ${number}</p>
              <p class="moodle-question-state">Ainda não respondida</p>
            </div>
            <div class="moodle-question-tools">
              <span>Vale 1,00 ponto(s)</span>
              <button class="moodle-flag" type="button" aria-label="Marcar questão demonstrativa">⚑ Marcar questão</button>
            </div>
          </header>

          <div class="moodle-question-body">
            <div class="moodle-number" aria-hidden="true">${number}</div>
            <div class="moodle-content">
              <p class="moodle-label">Texto da questão</p>
              <div class="moodle-statement">${question.statementHtml}</div>
              <div class="moodle-actions-row" aria-hidden="true">
                <button class="moodle-check" type="button">Verificar</button>
                <button class="moodle-next" type="button">Próxima página</button>
              </div>
            </div>
          </div>

          <div class="moodle-feedback">
            <p class="moodle-label">Feedback</p>
            <div>${question.solutionHtml}</div>
          </div>
        </article>

        <aside class="moodle-navigation" aria-label="Navegação simulada do questionário">
          <h4>Navegação do questionário</h4>
          <div class="moodle-nav-grid">
            <span class="moodle-nav-item current">${number}</span>
            <span class="moodle-nav-item">2</span>
            <span class="moodle-nav-item">3</span>
          </div>
          <p class="moodle-nav-status">Questão atual: ${escapeHtml(question.subject)}</p>
          <button class="moodle-finish" type="button">Terminar tentativa...</button>
        </aside>
      </div>

      <p class="moodle-note">
        Esta é uma simulação visual inspirada em uma tentativa de quiz. Não é uma cópia exata da interface do Moodle,
        não usa tema oficial e não exporta XML avaliativo.
      </p>
    </section>
  `;
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
