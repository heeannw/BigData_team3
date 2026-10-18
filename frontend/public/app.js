/* =========================
   API
========================= */

const API_ENDPOINT =
  '/api/rag-chat';


/* =========================
   DOM
========================= */

const operationModeButton =
  document.getElementById(
    'operationModeButton',
  );

const diagnosisModeButton =
  document.getElementById(
    'diagnosisModeButton',
  );

const modeLabel =
  document.getElementById(
    'modeLabel',
  );

const pageTitle =
  document.getElementById(
    'pageTitle',
  );

const pageDescription =
  document.getElementById(
    'pageDescription',
  );

const conversation =
  document.getElementById(
    'conversation',
  );

const exampleQuestions =
  document.getElementById(
    'exampleQuestions',
  );

const logToggleButton =
  document.getElementById(
    'logToggleButton',
  );

const logInputArea =
  document.getElementById(
    'logInputArea',
  );

const logCloseButton =
  document.getElementById(
    'logCloseButton',
  );

const logInput =
  document.getElementById(
    'logInput',
  );

const chatForm =
  document.getElementById(
    'chatForm',
  );

const questionInput =
  document.getElementById(
    'questionInput',
  );

const sendButton =
  document.getElementById(
    'sendButton',
  );


/* =========================
   State
========================= */

let currentMode =
  'operation';

const conversations = {
  operation: document.createElement('div'),
  diagnosis: document.createElement('div')
};

const CHAT_STORAGE_KEY = 'offline-rag-chat-history-v1';

// 현재 화면의 대화 내용을 저장
function saveConversation() {
  const getCleanHtml = (element) => {
    const clone = element.cloneNode(true);
    clone.querySelectorAll('#loadingMessage').forEach(
      (node) => node.remove()
    );
    return clone.innerHTML;
  };

  try {
    localStorage.setItem(
      CHAT_STORAGE_KEY,
      JSON.stringify({
        operation: getCleanHtml(
          currentMode === 'operation'
            ? conversation
            : conversations.operation
        ),
        diagnosis: getCleanHtml(
          currentMode === 'diagnosis'
            ? conversation
            : conversations.diagnosis
        )
      })
    );
  } catch (error) {
    console.error('채팅 기록 저장 실패:', error);
  }
}

// 저장된 대화 복원
function loadConversations() {
  try {
    const saved = JSON.parse(
      localStorage.getItem(CHAT_STORAGE_KEY) || '{}'
    );

    conversations.operation.innerHTML =
      saved.operation || '';

    conversations.diagnosis.innerHTML =
      saved.diagnosis || '';

  } catch (error) {
    console.error('채팅 기록 복원 실패:', error);
  }
}

let isLoading =
  false;

let loadingTimer =
  null;

let loadingStartedAt =
  0;


/* =========================
   Examples
========================= */

const EXAMPLES = {

  operation: [
    'Docker Compose 서비스를 어떻게 재시작해?',
    '문서를 다시 적재하려면 어떻게 해야 해?',
    '서비스 상태를 확인하는 방법을 알려줘.',
  ],

  diagnosis: [
    'n8n에서 Qdrant 연결이 안 됩니다.',
    'Docker 컨테이너가 계속 재시작됩니다.',
  ],

};


/* =========================
   Source titles
========================= */

const SOURCE_TITLE_MAP = {

  'docker_compose_operation.md':
    'Docker Compose 운영 가이드',

  'document_reingestion.md':
    '문서 재적재 방법',

  'env_configuration.md':
    '환경 설정 가이드',

  'health_check_guide.md':
    '시스템 상태 확인 방법',

  'offline_install_guide.md':
    '오프라인 설치 가이드',

  'workflow_backup_restore.md':
    '워크플로 백업 및 복구',

  'browser_request_failed_cors.md':
    '브라우저 요청 오류 해결 방법',

  'chat_ui_access_failed.md':
    '채팅 화면 접속 문제 해결',

  'container_restart_loop.md':
    '컨테이너 재시작 문제 해결',

  'healthz_readiness_check.md':
    '서비스 준비 상태 점검',

  'ingestion_no_documents.md':
    '문서 적재 오류 해결 방법',

  'ollama_context_truncation.md':
    'Ollama 응답 잘림 문제 해결',

  'ollama_model_issues.md':
    'Ollama 모델 문제 해결',

  'port_conflict.md':
    '포트 충돌 해결 방법',

  'service_connection_failed.md':
    '서비스 연결 실패 해결 방법',

  'sh_script_line_ending_error.md':
    '스크립트 줄바꿈 오류 해결',

  'webhook_not_triggering.md':
    'Webhook 실행 문제 해결',

  'encryption_key_and_credentials.md':
    '암호화 키 및 자격증명 관리',

  'offline_import_and_secrets.md':
    '오프라인 환경 보안 정보 관리',

  'chunk_tuning_guide.md':
    '문서 청크 설정 가이드',

  'rag_overview.md':
    'RAG 시스템 구성 안내',

};


/* =========================
   Mode
========================= */

function setMode(
  mode,
) {

  if (isLoading) {
    return;
  }

  if (currentMode !== mode) {
    // 현재 화면의 대화를 이전 모드에 보관
    conversations[currentMode].replaceChildren(
      ...Array.from(conversation.childNodes)
    );

    // 새 모드의 대화를 화면으로 이동
    currentMode = mode;

    conversation.replaceChildren(
      ...Array.from(conversations[currentMode].childNodes)
    );
  }

  // 마지막으로 선택한 모드 기억
  localStorage.setItem('offline-rag-last-mode', currentMode);

  // 변경된 대화 기록 저장
  saveConversation();

  const isOperation =
    mode === 'operation';

  operationModeButton.classList.toggle(
    'active',
    isOperation,
  );

  diagnosisModeButton.classList.toggle(
    'active',
    !isOperation,
  );

  if (isOperation) {

    modeLabel.textContent =
      '운영 질의';

    pageTitle.textContent =
      '무엇을 도와드릴까요?';

    pageDescription.textContent =
      'Docker, n8n, Qdrant, Ollama 등 내부 운영 문서를 기반으로 답변합니다.';

    questionInput.placeholder =
      '운영 관련 질문을 입력하세요.';

    logToggleButton.classList.add(
      'hidden',
    );

    closeLogInput();

  } else {

    modeLabel.textContent =
      '장애 진단';

    pageTitle.textContent =
      '어떤 문제가 발생했나요?';

    pageDescription.textContent =
      '문제 상황을 입력하면 관련 장애 대응 자료를 확인합니다.';

    questionInput.placeholder =
      '발생한 문제를 설명해 주세요.';

    logToggleButton.classList.remove(
      'hidden',
    );

  }

  renderExamples();
  questionInput.focus({ preventScroll: true });

  // 애니메이션 없이 즉시 맨 아래로 이동
  window.scrollTo({
    top: document.documentElement.scrollHeight,
    behavior: 'instant'
  });
}


/* =========================
   Examples
========================= */

function renderExamples() {

  exampleQuestions.innerHTML =
    '';

  EXAMPLES[currentMode].forEach(
    (
      question,
    ) => {

      const button =
        document.createElement(
          'button',
        );

      button.type =
        'button';

      button.className =
        'example-button';

      button.textContent =
        question;

      button.title =
        question;

      button.disabled =
        isLoading;

      button.addEventListener(
        'click',
        () => {

          if (isLoading) {
            return;
          }

          questionInput.value =
            question;

          autoResizeTextarea();

          questionInput.focus();
        },
      );

      exampleQuestions.appendChild(
        button,
      );
    },
  );
}


/* =========================
   Log input
========================= */

function openLogInput() {

  if (isLoading) {
    return;
  }

  logInputArea.classList.remove(
    'hidden',
  );

  logToggleButton.innerHTML = `
    <span class="log-plus">
      −
    </span>

    오류 로그 닫기
  `;

  logInput.focus();
}


function closeLogInput() {

  logInputArea.classList.add(
    'hidden',
  );

  logToggleButton.innerHTML = `
    <span class="log-plus">
      +
    </span>

    오류 로그 추가
  `;
}


function toggleLogInput() {
  const isHidden =
    logInputArea.classList.contains('hidden');

  if (isLoading) {
    // 처리 중에는 열지 못하지만 닫기는 허용
    if (!isHidden) {
      closeLogInput();
    }
    return;
  }

  if (isHidden) {
    openLogInput();
  } else {
    closeLogInput();
  }
}


/* =========================
   User message
========================= */

function appendUserMessage(
  message,
  logText = '',
) {

  const wrapper =
    document.createElement(
      'div',
    );

  wrapper.className =
    'message user';

  const logHtml =
    logText
      ? `
        <div class="user-log-card">

          <div class="user-log-header">

            <span class="user-log-label">
              오류 로그
            </span>

          </div>

          <pre class="user-log-text">${escapeHtml(logText)}</pre>

        </div>
      `
      : '';

  wrapper.innerHTML = `
    <div class="user-message-group">

      <div class="user-bubble">${escapeHtml(message)}</div>

      ${logHtml}

    </div>
  `;

  conversation.appendChild(
    wrapper,
  );

  saveConversation();
  scrollToBottom();
}


/* =========================
   Loading
========================= */

function appendLoading() {

  removeLoading();

  loadingStartedAt =
    Date.now();

  const wrapper =
    document.createElement(
      'div',
    );

  wrapper.id =
    'loadingMessage';

  wrapper.className =
    'message assistant';

  wrapper.innerHTML = `
    <div class="loading-card">

      <div class="loading-spinner">
      </div>

      <div class="loading-text">

        <strong>
          답변을 준비하고 있습니다.
        </strong>

        <span id="loadingElapsed">
          관련 자료 확인 중 · 0초
        </span>

      </div>

    </div>
  `;

  conversation.appendChild(
    wrapper,
  );

  updateLoadingTime();

  loadingTimer =
    window.setInterval(
      updateLoadingTime,
      1000,
    );

  scrollToBottom();
}


function updateLoadingTime() {

  const element =
    document.getElementById(
      'loadingElapsed',
    );

  if (!element) {
    return;
  }

  const seconds =
    Math.floor(
      (
        Date.now() -
        loadingStartedAt
      ) /
      1000,
    );

  element.textContent =
    `관련 자료 확인 중 · ${seconds}초`;
}


function removeLoading() {

  if (loadingTimer) {

    window.clearInterval(
      loadingTimer,
    );

    loadingTimer =
      null;
  }

  const element =
    document.getElementById(
      'loadingMessage',
    );

  if (element) {
    element.remove();
  }
}


/* =========================
   Answer
========================= */

function appendAnswer(
  response,
  requestMode,
) {
  const wrapper =
    document.createElement(
      'div',
    );

  wrapper.className =
    'message assistant';

  const isDiagnosis =
    requestMode ===
    'diagnosis';

  const answerText =
    getAnswerText(
      response,
    );

  const answerHtml =
    isDiagnosis
      ? renderDiagnosis(
          response,
        )
      : formatAnswerText(
          answerText,
        );

  const sources =
    groupSourcesByDocument(
      Array.isArray(
        response.sources,
      )
        ? response.sources
        : [],
    );

  const responseTime =
    getResponseTime(
      response,
    );

  const abstainMessage =
    '제공된 내부 자료에서는 확인할 수 없습니다.';

  const diagnosisSummary =
    response?.diagnosis?.summary ??
    '';

  const isCompactAnswer =
    sources.length === 0 &&
    (
      answerText.trim() ===
        abstainMessage ||
      diagnosisSummary.trim() ===
        abstainMessage
    );

  const answerCardClass =
    isCompactAnswer
      ? 'answer-card compact-answer'
      : 'answer-card';

  wrapper.innerHTML = `
    <div class="${answerCardClass}">

      <div class="answer-main">

        <div class="answer-body">
          ${answerHtml}
        </div>

      </div>

      ${
        renderSources(
          sources,
          responseTime,
        )
      }

    </div>
  `;

  conversation.appendChild(
    wrapper,
  );

  saveConversation();
  scrollToBottom();
}

/* =========================
   Operation answer
========================= */

function getAnswerText(
  response,
) {

  if (
    typeof response.answer ===
    'string'
  ) {
    return response.answer;
  }

  if (
    typeof response.message ===
    'string'
  ) {
    return response.message;
  }

  if (
    typeof response.output ===
    'string'
  ) {
    return response.output;
  }

  return '답변을 확인할 수 없습니다.';
}


/* =========================
   Diagnosis
========================= */

function renderDiagnosis(
  response,
) {
  const diagnosis =
    response.diagnosis;

  const abstainMessage =
    '제공된 내부 자료에서는 확인할 수 없습니다.';

  if (
    !diagnosis ||
    typeof diagnosis !==
      'object'
  ) {
    const fallback =
      response.answer ??
      '진단 결과를 확인할 수 없습니다.';

    if (
      String(fallback).trim() ===
      abstainMessage
    ) {
      return `
        <p>
          ${formatInlineText(
            fallback,
          )}
        </p>
      `;
    }

    return `
      <div class="diagnosis-section">

        <h3>
          진단 요약
        </h3>

        <p>
          ${formatInlineText(
            fallback,
          )}
        </p>

      </div>
    `;
  }

  const summary =
    diagnosis.summary ??
    response.answer ??
    '진단 요약을 확인할 수 없습니다.';

  const causes =
    ensureArray(
      diagnosis.possibleCauses,
    );

  const checkSteps =
    ensureArray(
      diagnosis.checkSteps,
    );

  const actions =
    ensureArray(
      diagnosis.actions,
    );

  const isAbstained =
    String(summary).trim() ===
    abstainMessage;

  if (isAbstained) {
    return `
      <p>
        ${formatInlineText(
          summary,
        )}
      </p>
    `;
  }

  return `
    <div class="diagnosis-section">

      <h3>
        진단 요약
      </h3>

      <p>
        ${formatInlineText(
          summary,
        )}
      </p>

    </div>

    ${
      renderDiagnosisList(
        '가능한 원인',
        causes,
        false,
      )
    }

    ${
      renderDiagnosisList(
        '확인 순서',
        checkSteps,
        true,
      )
    }

    ${
      renderDiagnosisList(
        '권장 조치',
        actions,
        true,
      )
    }
  `;
}

function renderDiagnosisList(
  title,
  items,
  ordered,
) {

  if (!items.length) {
    return '';
  }

  const tag =
    ordered
      ? 'ol'
      : 'ul';

  const listHtml =
    items
      .map(
        (
          item,
        ) => `
          <li>
            ${formatInlineText(
              String(item),
            )}
          </li>
        `,
      )
      .join('');

  return `
    <div class="diagnosis-section">

      <h3>
        ${escapeHtml(title)}
      </h3>

      <${tag}>
        ${listHtml}
      </${tag}>

    </div>
  `;
}


/* =========================
   Text formatting
========================= */

function normalizeModelAnswer(
  text,
) {

  return String(
    text ?? '',
  )
    .replace(
      /```(?:powershell|bash|shell|cmd|batch|docker|json)?/gi,
      '',
    )
    .replace(
      /```/g,
      '',
    )
    .replace(
      /\bpowershell\s+powershell\b/gi,
      'powershell',
    )
    .trim();
}


function formatAnswerText(
  text,
) {

  const normalized =
    normalizeModelAnswer(
      text,
    );

  const lines =
    normalized
      .split(
        /\r?\n/,
      )
      .map(
        (
          line,
        ) =>
          line.trim(),
      );

  let html =
    '';

  let listType =
    null;

  const closeList =
    () => {

      if (!listType) {
        return;
      }

      html +=
        `</${listType}>`;

      listType =
        null;
    };

  lines.forEach(
    (
      line,
    ) => {

      if (!line) {
        closeList();
        return;
      }

      const numbered =
        line.match(
          /^\d+[.)]\s+(.+)$/,
        );

      if (numbered) {

        if (
          listType !==
          'ol'
        ) {

          closeList();

          html +=
            '<ol>';

          listType =
            'ol';
        }

        html += `
          <li>
            ${formatInlineText(
              numbered[1],
            )}
          </li>
        `;

        return;
      }

      const bullet =
        line.match(
          /^[-*•]\s+(.+)$/,
        );

      if (bullet) {

        if (
          listType !==
          'ul'
        ) {

          closeList();

          html +=
            '<ul>';

          listType =
            'ul';
        }

        html += `
          <li>
            ${formatInlineText(
              bullet[1],
            )}
          </li>
        `;

        return;
      }

      closeList();

      html += `
        <p>
          ${formatInlineText(line)}
        </p>
      `;
    },
  );

  closeList();

  return html;
}


function formatInlineText(
  text,
) {

  let escaped =
    escapeHtml(
      text,
    );

  /*
   * 모델이 이미 백틱으로 감싼
   * 명령어 / 경로
   */
  escaped =
    escaped.replace(
      /`([^`]+)`/g,
      '<code>$1</code>',
    );

  return escaped;
}


/* =========================
   Sources
========================= */

function groupSourcesByDocument(
  sources,
) {

  const map =
    new Map();

  sources.forEach(
    (
      source,
    ) => {

      if (!source) {
        return;
      }

      const documentName =
        source.documentName ??
        source.fileName ??
        source.source ??
        '';

      if (!documentName) {
        return;
      }

      if (
        !map.has(
          documentName,
        )
      ) {

        map.set(
          documentName,
          {
            documentName,

            category:
              source.category ??
              '',

            sections:
              [],
          },
        );
      }

      const item =
        map.get(
          documentName,
        );

      if (
        source.section &&
        !item.sections.includes(
          source.section,
        )
      ) {

        item.sections.push(
          source.section,
        );
      }
    },
  );

  return Array.from(
    map.values(),
  );
}


function renderSources(
  sources,
  responseTime,
) {

  /*
   * 출처가 없으면 footer 자체를 표시하지 않는다.
   *
   * 예:
   * "제공된 내부 자료에서는 확인할 수 없습니다."
   *
   * 이런 abstain 응답에서
   * 빈 "참고 자료" 영역이 나오지 않도록 한다.
   */
  if (!sources.length) {
    return '';
  }

  const sourceItems =
    sources
      .map(
        (
          source,
          index,
        ) => {

          const title =
            getFriendlySourceTitle(
              source.documentName,
            );

          const metadata =
            [
              source.category,
              ...source.sections,
            ]
              .filter(Boolean)
              .join(
                ' · ',
              );

          return `
            <div class="source-item">

              <strong>
                ${index + 1}. ${escapeHtml(title)}
              </strong>

              ${
                metadata
                  ? `
                    <span>
                      ${escapeHtml(metadata)}
                    </span>
                  `
                  : ''
              }

            </div>
          `;
        },
      )
      .join('');

  return `
    <div class="answer-footer">

      <div class="answer-footer-header">

        <span class="source-title">
          참고 자료 ${sources.length}개
        </span>

        ${
          responseTime !== ''
            ? `
              <span class="response-time">
                응답 시간 ${escapeHtml(responseTime)}
              </span>
            `
            : ''
        }

      </div>

      <div class="source-list">
        ${sourceItems}
      </div>

    </div>
  `;
}


function getFriendlySourceTitle(
  documentName,
) {

  const normalized =
    String(
      documentName ?? '',
    )
      .replace(
        /\\/g,
        '/',
      )
      .split('/')
      .pop();

  if (
    SOURCE_TITLE_MAP[
      normalized
    ]
  ) {

    return SOURCE_TITLE_MAP[
      normalized
    ];
  }

  return normalized
    .replace(
      /\.(md|txt)$/i,
      '',
    )
    .replace(
      /[_-]+/g,
      ' ',
    );
}


/* =========================
   Response time
========================= */

function getResponseTime(
  response,
) {

  const value =
    response.responseTime ??
    response.responseTimeMs ??
    response.durationMs;

  if (
    value === undefined ||
    value === null
  ) {
    return '';
  }

  const numberValue =
    Number(
      value,
    );

  if (
    Number.isNaN(
      numberValue,
    )
  ) {

    return String(
      value,
    );
  }

  if (
    numberValue >=
    1000
  ) {

    return `${
      (
        numberValue /
        1000
      ).toFixed(
        1,
      )
    }초`;
  }

  return `${numberValue}ms`;
}


/* =========================
   Error
========================= */

function appendError(
  message,
) {

  const wrapper =
    document.createElement(
      'div',
    );

  wrapper.className =
    'message assistant error-message';

  const rawMessage =
    String(
      message ??
      '알 수 없는 오류가 발생했습니다.',
    );

  let userMessage =
    rawMessage;

  if (
    rawMessage.includes(
      'The execution was cancelled manually',
    )
  ) {

    userMessage =
      '요청이 중단되었습니다.';
  }

  if (
    rawMessage.includes(
      'The operation was aborted',
    )
  ) {

    userMessage =
      '요청 처리가 중단되었습니다.';
  }

  if (
    rawMessage.includes(
      'Failed to fetch',
    )
  ) {

    userMessage =
      '서버에 연결할 수 없습니다.';
  }

  wrapper.innerHTML = `
    <div class="message-content">

      <div class="error-card">

        <strong>
          요청을 처리하지 못했습니다.
        </strong>

        <span>
          ${escapeHtml(userMessage)}
        </span>

      </div>

    </div>
  `;

  conversation.appendChild(
    wrapper,
  );

  saveConversation();
  scrollToBottom();
}


/* =========================
   Request
========================= */

async function sendQuestion() {

  if (isLoading) {
    return;
  }

  const question =
    questionInput.value.trim();

  if (!question) {

    questionInput.focus();

    return;
  }

  const errorLog =
    logInput.value.trim();

  /*
   * 요청 시작 시점의 모드를 저장한다.
   *
   * 요청 처리 중 화면 모드가 바뀌더라도
   * 응답 표시 형식이 꼬이지 않게 한다.
   */
  const requestMode =
    currentMode;

  appendUserMessage(
    question,

    requestMode ===
      'diagnosis'
      ? errorLog
      : '',
  );

  questionInput.value =
    '';

  autoResizeTextarea();

  setLoadingState(
    true,
  );

  appendLoading();

  try {

    const body = {

      requestType:
        requestMode,

      question,
    };

    if (
      requestMode ===
        'diagnosis' &&
      errorLog
    ) {

      body.logText =
        errorLog;
    }

    const response =
      await fetch(
        API_ENDPOINT,
        {

          method:
            'POST',

          headers: {

            'Content-Type':
              'application/json',
          },

          body:
            JSON.stringify(
              body,
            ),
        },
      );

    let data =
      null;

    try {

      data =
        await response.json();

    } catch {

      throw new Error(
        `서버 응답 형식이 올바르지 않습니다. (${response.status})`,
      );
    }

    if (!response.ok) {

      throw new Error(
        data?.message ??
        data?.error ??
        `요청에 실패했습니다. (${response.status})`,
      );
    }

    removeLoading();

    appendAnswer(
      data,
      requestMode,
    );

  } catch (
    error
  ) {

    removeLoading();

    appendError(
      error instanceof Error
        ? error.message
        : String(
            error,
          ),
    );

  } finally {

    setLoadingState(
      false,
    );

    questionInput.focus();
  }
}


/* =========================
   Loading state
========================= */

function setLoadingState(
  loading,
) {

  isLoading =
    loading;

  sendButton.disabled =
    loading;

  questionInput.disabled =
    loading;

  logToggleButton.disabled =
  loading && logInputArea.classList.contains('hidden');

  logCloseButton.disabled = false;

  logInput.disabled =
    loading;

  operationModeButton.disabled =
    loading;

  diagnosisModeButton.disabled =
    loading;

  sendButton.textContent =
    loading
      ? '처리 중'
      : '보내기';

  renderExamples();
}


/* =========================
   Textarea
========================= */

function autoResizeTextarea() {

  questionInput.style.height =
    'auto';

  questionInput.style.height =
    `${Math.min(
      questionInput.scrollHeight,
      120,
    )}px`;
}


/* =========================
   Helpers
========================= */

function ensureArray(
  value,
) {

  if (
    Array.isArray(
      value,
    )
  ) {

    return value;
  }

  if (
    value === null ||
    value === undefined ||
    value === ''
  ) {

    return [];
  }

  return [
    value,
  ];
}


function escapeHtml(
  value,
) {

  return String(
    value ?? '',
  )
    .replace(
      /&/g,
      '&amp;',
    )
    .replace(
      /</g,
      '&lt;',
    )
    .replace(
      />/g,
      '&gt;',
    )
    .replace(
      /"/g,
      '&quot;',
    )
    .replace(
      /'/g,
      '&#039;',
    );
}


function scrollToBottom() {

  window.requestAnimationFrame(
    () => {

      window.scrollTo({

        top:
          document
            .documentElement
            .scrollHeight,

        behavior:
          'smooth',
      });
    },
  );
}


/* =========================
   Events
========================= */

operationModeButton.addEventListener(
  'click',
  () => {

    setMode(
      'operation',
    );
  },
);


diagnosisModeButton.addEventListener(
  'click',
  () => {

    setMode(
      'diagnosis',
    );
  },
);


logToggleButton.addEventListener(
  'click',
  toggleLogInput,
);


logCloseButton.addEventListener(
  'click',
  closeLogInput,
);


chatForm.addEventListener(
  'submit',
  (
    event,
  ) => {

    event.preventDefault();

    sendQuestion();
  },
);


questionInput.addEventListener(
  'input',
  autoResizeTextarea,
);


questionInput.addEventListener(
  'keydown',
  (
    event,
  ) => {

    if (
      event.key ===
        'Enter' &&
      !event.shiftKey
    ) {

      event.preventDefault();

      sendQuestion();
    }
  },
);


/* =========================
   Init
========================= */

// 저장된 운영 질의 / 장애 진단 기록 불러오기
loadConversations();

// 마지막으로 사용한 모드 확인
const savedMode = localStorage.getItem('offline-rag-last-mode');

const initialMode =
  savedMode === 'diagnosis' ? 'diagnosis' : 'operation';

// 초기 모드 설정
currentMode = initialMode;

// 저장된 대화를 실제 채팅창에 표시
conversation.replaceChildren(
  ...Array.from(conversations[initialMode].childNodes)
);

// 버튼과 화면 제목 등 초기화
setMode(initialMode);

autoResizeTextarea();