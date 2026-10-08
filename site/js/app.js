const state = {
  questions: [],
  search: '',
  area: '',
  subject: '',
  enemYear: '',
  enemSkill: '',
  aMin: null,
  aMax: null,
  bMin: null,
  bMax: null,
  cMin: null,
  cMax: null,
  skills: {}
};

const elements = {
  search: document.querySelector('#search'),
  areaFilter: document.querySelector('#area-filter'),
  subjectFilter: document.querySelector('#subject-filter'),
  enemYearFilter: document.querySelector('#enem-year-filter'),
  enemSkillFilter: document.querySelector('#enem-skill-filter'),
  aMin: document.querySelector('#param-a-min'),
  aMax: document.querySelector('#param-a-max'),
  bMin: document.querySelector('#param-b-min'),
  bMax: document.querySelector('#param-b-max'),
  cMin: document.querySelector('#param-c-min'),
  cMax: document.querySelector('#param-c-max'),
  count: document.querySelector('#count'),
  catalog: document.querySelector('#catalog'),
  template: document.querySelector('#question-template')
};

async function loadQuestions() {
  try {
    const [questionsResponse, skillsResponse] = await Promise.all([
      fetch('data/questoes-demo.json'),
      fetch('data/enem-habilidades-cn.json')
    ]);
    if (!questionsResponse.ok) {
      throw new Error(`Erro ao carregar questões: ${questionsResponse.status}`);
    }
    if (!skillsResponse.ok) {
      throw new Error(`Erro ao carregar habilidades ENEM: ${skillsResponse.status}`);
    }

    const data = await questionsResponse.json();
    const skillData = await skillsResponse.json();
    state.questions = data.questions.filter((question) => question.visibility === 'demo');
    state.skills = Object.fromEntries(
      skillData.skills.map((skill) => [skill.code, skill])
    );
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
  const enemYears = uniqueSorted(
    state.questions
      .map((question) => question.enemSource?.year)
      .filter(Boolean)
      .map(String)
  );
  const enemSkills = uniqueSorted(
    state.questions
      .map((question) => question.enemSource?.skillCode)
      .filter(Boolean)
  ).map((code) => ({
    value: code,
    label: `${code} — ${skillLabel(code)}`
  }));

  fillSelect(elements.areaFilter, areas, 'Todas');
  fillSelect(elements.subjectFilter, subjects, 'Todos');
  fillSelect(elements.enemYearFilter, enemYears, 'Todos');
  fillSelect(elements.enemSkillFilter, enemSkills, 'Todas');

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

  elements.enemYearFilter.addEventListener('change', (event) => {
    state.enemYear = event.target.value;
    render();
  });

  elements.enemSkillFilter.addEventListener('change', (event) => {
    state.enemSkill = event.target.value;
    render();
  });

  [
    ['aMin', elements.aMin],
    ['aMax', elements.aMax],
    ['bMin', elements.bMin],
    ['bMax', elements.bMax],
    ['cMin', elements.cMin],
    ['cMax', elements.cMax]
  ].forEach(([stateKey, input]) => {
    input.addEventListener('input', (event) => {
      state[stateKey] = parseOptionalNumber(event.target.value);
      render();
    });
  });
}

function fillSelect(select, values, defaultLabel) {
  select.innerHTML = `<option value="">${defaultLabel}</option>`;
  values.forEach((item) => {
    const value = typeof item === 'string' ? item : item.value;
    const label = typeof item === 'string' ? item : item.label;
    const option = document.createElement('option');
    option.value = value;
    option.textContent = label;
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
    question.enemSource?.year,
    question.enemSource?.skillCode,
    question.enemSource?.skillText,
    question.enemSource?.coItem,
    ...(question.tags || [])
  ]
    .join(' ')
    .toLowerCase();

  return (
    (!state.search || haystack.includes(state.search)) &&
    (!state.area || question.area === state.area) &&
    (!state.subject || question.subject === state.subject) &&
    (!state.enemYear || String(question.enemSource?.year || '') === state.enemYear) &&
    (!state.enemSkill || question.enemSource?.skillCode === state.enemSkill) &&
    parameterInRange(question.enemSource?.a, state.aMin, state.aMax) &&
    parameterInRange(question.enemSource?.b, state.bMin, state.bMax) &&
    parameterInRange(question.enemSource?.c, state.cMin, state.cMax)
  );
}

function renderQuestion(question, index) {
  const fragment = elements.template.content.cloneNode(true);
  const card = fragment.querySelector('.question-card');
  const title = fragment.querySelector('h2');
  const id = fragment.querySelector('.question-id');
  const meta = fragment.querySelector('.question-meta');
  const tags = fragment.querySelector('.tags');
  const enemSource = fragment.querySelector('.enem-source');
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
  enemSource.innerHTML = question.enemSource ? renderEnemSource(question.enemSource) : '';

  (question.tags || []).forEach((tag) => {
    const item = document.createElement('span');
    item.className = 'tag';
    item.textContent = tag;
    tags.appendChild(item);
  });

  return fragment;
}

function renderEnemSource(source) {
  const abandoned = source.abandoned
    ? `<span class="enem-status abandoned">Item abandonado${source.abandonmentReason ? `: ${escapeHtml(source.abandonmentReason)}` : ''}</span>`
    : '<span class="enem-status">Item calibrado</span>';

  const parameters = source.abandoned
    ? '<p class="enem-parameters">Parâmetros TRI indisponíveis para este item abandonado.</p>'
    : `
      <dl class="enem-parameters">
        <div><dt>a</dt><dd>${formatParameter(source.a)}</dd></div>
        <div><dt>b</dt><dd>${formatParameter(source.b)}</dd></div>
        <div><dt>c</dt><dd>${formatParameter(source.c)}</dd></div>
      </dl>
    `;

  return `
    <details class="enem-source-card">
      <summary>Metadados do item-fonte ENEM</summary>
      <div class="enem-source-content">
        <div class="enem-source-heading">
          <div>
            <p class="eyebrow">Item-fonte ENEM</p>
            <h3>ENEM ${escapeHtml(source.year)} · questão ${escapeHtml(source.questionNumber)}</h3>
          </div>
          ${abandoned}
        </div>

        <dl class="enem-meta-grid">
          <div><dt>Aplicação</dt><dd>${escapeHtml(source.application)}</dd></div>
          <div><dt>Caderno</dt><dd>${escapeHtml(source.caderno)} · ${escapeHtml(source.color)}</dd></div>
          <div><dt>CO_ITEM</dt><dd>${escapeHtml(source.coItem)}</dd></div>
          <div><dt>Habilidade</dt><dd>${escapeHtml(source.skillCode)}</dd></div>
          <div><dt>Gabarito original</dt><dd>${escapeHtml(source.originalAnswer)}</dd></div>
        </dl>

        <p class="enem-skill"><strong>${escapeHtml(source.skillCode)}:</strong> ${escapeHtml(skillLabel(source.skillCode))}</p>
        ${parameters}
        ${renderIcc(source)}
        <p class="enem-warning">
          Parâmetros referentes ao item original aplicado pelo Inep; não constituem calibração da versão adaptada do BancoFisica.
        </p>
        <p class="enem-adaptation">${escapeHtml(source.adaptationNote)}</p>
        <p><a href="${escapeHtml(source.sourceUrl)}" rel="noopener noreferrer">Consultar fonte oficial do Inep</a></p>
      </div>
    </details>
  `;
}

function renderIcc(source) {
  if (source.abandoned) {
    return '';
  }

  const a = Number(source.a);
  const b = Number(source.b);
  const c = Number(source.c);
  if (![a, b, c].every(Number.isFinite)) {
    return '';
  }

  const width = 520;
  const height = 260;
  const left = 44;
  const right = 18;
  const top = 18;
  const bottom = 40;
  const plotWidth = width - left - right;
  const plotHeight = height - top - bottom;

  const x = (theta) => left + ((theta + 3) / 6) * plotWidth;
  const y = (probability) => top + (1 - probability) * plotHeight;
  const probability = (theta) => c + (1 - c) / (1 + Math.exp(-a * (theta - b)));

  const points = [];
  for (let i = 0; i <= 120; i += 1) {
    const theta = -3 + i * 0.05;
    points.push(`${x(theta).toFixed(1)},${y(probability(theta)).toFixed(1)}`);
  }

  const xTicks = [-3, -2, -1, 0, 1, 2, 3]
    .map((tick) => `
      <line x1="${x(tick)}" y1="${top + plotHeight}" x2="${x(tick)}" y2="${top + plotHeight + 5}" class="icc-axis" />
      <text x="${x(tick)}" y="${height - 12}" text-anchor="middle" class="icc-label">${tick}</text>
    `)
    .join('');

  const yTicks = [0, 0.25, 0.5, 0.75, 1]
    .map((tick) => `
      <line x1="${left - 5}" y1="${y(tick)}" x2="${left}" y2="${y(tick)}" class="icc-axis" />
      <text x="${left - 9}" y="${y(tick) + 4}" text-anchor="end" class="icc-label">${tick.toFixed(2)}</text>
    `)
    .join('');

  return `
    <figure class="icc-figure">
      <svg viewBox="0 0 ${width} ${height}" role="img" aria-label="Curva característica do item original do ENEM">
        <line x1="${left}" y1="${top}" x2="${left}" y2="${top + plotHeight}" class="icc-axis" />
        <line x1="${left}" y1="${top + plotHeight}" x2="${left + plotWidth}" y2="${top + plotHeight}" class="icc-axis" />
        ${xTicks}
        ${yTicks}
        <polyline points="${points.join(' ')}" class="icc-line" />
        <text x="${left + plotWidth / 2}" y="${height - 1}" text-anchor="middle" class="icc-label">proficiência θ</text>
        <text x="13" y="${top + plotHeight / 2}" text-anchor="middle" transform="rotate(-90 13 ${top + plotHeight / 2})" class="icc-label">P(acerto)</text>
      </svg>
      <figcaption>CCI 3PL do item original do ENEM, calculada com os parâmetros publicados pelo Inep.</figcaption>
    </figure>
  `;
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

function skillLabel(code) {
  return state.skills[code]?.label || code;
}

function formatParameter(value) {
  return Number(value).toLocaleString('pt-BR', { minimumFractionDigits: 3, maximumFractionDigits: 5 });
}

function parseOptionalNumber(value) {
  if (value === '') {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function parameterInRange(value, min, max) {
  if (min === null && max === null) {
    return true;
  }
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) {
    return false;
  }
  return (min === null || numeric >= min) && (max === null || numeric <= max);
}

function uniqueSorted(values) {
  return [...new Set(values.filter(Boolean))].sort((a, b) => a.localeCompare(b, 'pt-BR'));
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

loadQuestions();
