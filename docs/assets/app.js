const THEME_STORAGE_KEY = "mutype:theme";
const LANG_STORAGE_KEY = "mutype:lang";

const THEME_CHOICES = ["light", "dark"];
const LANG_CHOICES = ["zh", "en"];

const I18N = {
  en: {
    page_title: "MuType — calm typing practice for Emacs",
    page_description:
      "MuType is a minimal typing practice loop for Emacs. Calm rhythm, low distraction, steady flow.",
    og_title: "MuType",
    og_description: "MuType is a minimal typing practice loop for Emacs.",

    skip_to_content: "Skip to content",
    header_hint: "Type into stillness — minimal typing practice loop for Emacs",

    ml_major: "MuType-Web",

    epigraph_quote:
      "<p>菩提本无树，</p><p>明镜亦非台；</p><p>本来无一物，</p><p>何处惹尘埃？</p>",
    epigraph_author: "Huineng",
    epigraph_translation:
      "“Originally there is not a single thing—where could dust alight?”",

    hero_subtitle:
      "Type into stillness. Calm rhythm. Low distraction. Steady flow.",
    hero_meta_emacs: "Emacs 25.1+",
    hero_meta_deps: "No external runtime deps",
    hero_meta_license: "MIT",
    cta_install: "Install",
    cta_demo: "See demo",

    intro_title: "What is MuType?",

    demo_title: "Demo",
    demo_alt: "Screenshot of a MuType session in Emacs",
    demo_caption: "A MuType session in <code>*MuType*</code>.",

    features_title: "Features",
    feature_1: "Two modes: flow and precision.",
    feature_2: "HUD in the mode line: timer, progress, accuracy, zone.",
    feature_3: "Plain-text sources bundled in <code>sources/*.txt</code>.",
    feature_4: "Report buffer at session end.",
    feature_5: "Zero external dependencies.",

    name_title: "Name: Mu (無)",
    name_body_1:
      "“Mu” comes from the Chinese character “無” (simplified: “无”), literally “not / without”.",
    name_body_2:
      "In Chan/Zen, “mu” points to letting go of rigid judgments and returning to a clear, unforced mind.",
    name_body_3:
      "MuType uses this as a reminder: focus on the current character, keep a calm rhythm, and let mistakes pass.",

    install_title: "Install",
    install_melpa_title: "MELPA (recommended)",
    install_melpa_note: "Once MuType is available on MELPA, install with:",
    install_melpa_enable: "If you don't have MELPA enabled:",
    install_manual_title: "Manual (load-path)",
    install_straight_title: "straight.el (optional)",

    start_title: "Start",
    start_run_prefix: "Run",
    start_run_suffix: "to jump into <code>*MuType*</code> and start typing.",
    start_custom_prefix: "To choose mode/duration/source, use",
    start_custom_mid: "or",
    modes_title: "Modes",
    mode_flow: "mistakes do not block progress.",
    mode_precision: "you must type the correct character to advance.",

    session_title: "During a session",
    session_hud_intro: "The MuType HUD lives in the mode line and shows:",
    hud_1: "zone symbol (<code>·</code>, <code>:</code>, <code>*</code>, <code>●</code>)",
    hud_2: "timer and state (<code>running</code>/<code>paused</code>)",
    hud_3: "progress, accuracy, and current source label (clickable)",

    keys_title: "Common keys and commands",
    table_key: "Key / Command",
    table_action: "Action",
    action_pause: "Pause/resume",
    action_stop: "Stop session",
    action_next: "Next source (restart)",
    action_prev: "Previous source (restart)",
    action_pick: "Pick a source (restart)",
    action_report: "Open the last report",
    session_snapback:
      "Typing follows MuType's sequential index. If point is moved, input snaps back to the current training position.",

    sources_title: "Text sources",
    sources_body_1:
      "MuType intentionally reads plain text from the bundled <code>sources/*.txt</code> directory.",
    sources_body_2:
      "To add or tweak training text, edit or add <code>.txt</code> files under <code>sources/</code>. Since this directory is part of the installed package, upgrades may overwrite local changes—keep a copy of your custom texts.",

    custom_title: "Customization",
    custom_body: "Put something like this in your init file:",

    report_title: "Report",
    report_body_1:
      "MuType shows a report buffer when you stop a session or when the time limit is reached.",
    report_body_2: "Reopen the last report with",

    links_title: "Links",
    link_license: "License (MIT)",

    minibuffer_default: "mutype-mode",

    theme_label: "Theme",
    theme_light: "Light",
    theme_dark: "Dark",

    lang_label: "Lang",
    lang_zh: "中文",
    lang_en: "EN",

    pos_top: "Top",
    pos_bot: "Bot",
    pos_all: "All",
  },
  zh: {
    page_title: "MuType — Emacs 的平静打字练习",
    page_description:
      "MuType 是一个 Emacs 的极简打字练习循环：节奏平静、低干扰、重在稳定流畅。",
    og_title: "MuType",
    og_description: "MuType 是一个 Emacs 的极简打字练习循环。",

    skip_to_content: "跳到正文",
    header_hint: "极简的 Emacs 打字插件",

    ml_major: "MuType-Web",

    epigraph_quote:
      "<p>菩提本无树，</p><p>明镜亦非台；</p><p>本来无一物，</p><p>何处惹尘埃？</p>",
    epigraph_author: "六祖慧能",
    epigraph_translation: "",

    hero_subtitle:
      "通过打字进入“无”的境界。平静节奏、低干扰、稳定流畅。",
    hero_meta_emacs: "Emacs 25.1+",
    hero_meta_deps: "零外部依赖",
    hero_meta_license: "MIT",
    cta_install: "安装",
    cta_demo: "查看演示",

    intro_title: "MuType 是什么？",

    demo_title: "演示",
    demo_alt: "Emacs 中 MuType 会话截图",
    demo_caption: "<code>*MuType*</code> 中的一次练习会话。",

    features_title: "特性",
    feature_1: "两种模式：flow 与 precision。",
    feature_2: "HUD 在 mode line：计时、进度、准确率、分区。",
    feature_3: "自带纯文本来源：<code>sources/*.txt</code>。",
    feature_4: "结束自动生成报告缓冲区。",
    feature_5: "无外部运行时依赖。",

    name_title: "名字：Mu（无/無）",
    name_body_1: "“Mu” 源于中文“无/無”，常见含义是“没有/不”。",
    name_body_2:
      "在禅宗语境中，“无”不只是“没有”，更是指向放下分别与执著，回到当下的清明。",
    name_body_3:
      "MuType 用这个名字提醒自己：专注于当前字符，保持平静节奏，不把练习变成竞速。",

    install_title: "安装",
    install_melpa_title: "MELPA（推荐）",
    install_melpa_note: "MuType 上线 MELPA 后，可用以下方式安装：",
    install_melpa_enable: "若尚未启用 MELPA：",
    install_manual_title: "手动（load-path）",
    install_straight_title: "straight.el（可选）",

    start_title: "开始",
    start_run_prefix: "运行",
    start_run_suffix: "即可进入 <code>*MuType*</code> 并开始练习。",
    start_custom_prefix: "如需选择模式/时长/来源，可用",
    start_custom_mid: "或",
    modes_title: "模式",
    mode_flow: "错误不会阻塞前进。",
    mode_precision: "必须输入正确字符才会前进。",

    session_title: "练习中",
    session_hud_intro: "MuType 的 HUD 位于 mode line，包含：",
    hud_1: "分区符号（<code>·</code>、<code>:</code>、<code>*</code>、<code>●</code>）",
    hud_2: "计时与状态（<code>running</code>/<code>paused</code>）",
    hud_3: "进度、准确率、当前来源标签（可点击）",

    keys_title: "常用按键与命令",
    table_key: "按键 / 命令",
    table_action: "动作",
    action_pause: "暂停/继续",
    action_stop: "结束练习",
    action_next: "下一来源（重启）",
    action_prev: "上一来源（重启）",
    action_pick: "选择来源（重启）",
    action_report: "打开上一次报告",
    session_snapback:
      "输入始终按 MuType 的顺序索引推进。若移动 point，输入会自动回到当前训练位置。",

    sources_title: "文本来源",
    sources_body_1:
      "MuType 只读取包内自带的纯文本目录 <code>sources/*.txt</code>。",
    sources_body_2:
      "如需新增或调整练习文本，可在 <code>sources/</code> 下编辑或新增 <code>.txt</code> 文件。由于该目录属于安装包的一部分，升级可能覆盖本地改动——建议备份自定义文本。",

    custom_title: "自定义",
    custom_body: "在你的 init 文件中加入类似配置：",

    report_title: "报告",
    report_body_1: "结束练习或达到时间上限时，MuType 会打开报告缓冲区。",
    report_body_2: "可用以下命令重新打开上一次报告：",

    links_title: "链接",
    link_license: "许可证（MIT）",

    minibuffer_default: "mutype-mode",

    theme_label: "主题",
    theme_light: "明亮",
    theme_dark: "暗色",

    lang_label: "语言",
    lang_zh: "中文",
    lang_en: "EN",

    pos_top: "顶部",
    pos_bot: "底部",
    pos_all: "全部",
  },
};

function clampToOptions(value, options, fallback) {
  if (!value) return fallback;
  return options.includes(value) ? value : fallback;
}

function detectLanguage() {
  const preferred =
    (Array.isArray(navigator.languages) && navigator.languages[0]) ||
    navigator.language ||
    "en";
  return preferred.toLowerCase().startsWith("zh") ? "zh" : "en";
}

function prefersDark() {
  if (!window.matchMedia) return false;
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

function getResolvedTheme(choice) {
  if (choice === "dark") return "dark";
  if (choice === "light") return "light";
  return prefersDark() ? "dark" : "light";
}

function applyTheme(choice) {
  const root = document.documentElement;
  if (choice === "light" || choice === "dark") {
    root.setAttribute("data-theme", choice);
  } else {
    root.removeAttribute("data-theme");
  }
}

function setMetaI18nContent(lang) {
  const dict = I18N[lang] || I18N.en;
  for (const el of document.querySelectorAll("[data-i18n-content]")) {
    const key = el.getAttribute("data-i18n-content");
    if (!key) continue;
    const val = dict[key];
    if (typeof val === "string") el.setAttribute("content", val);
  }
}

function setTitleI18n(lang) {
  const dict = I18N[lang] || I18N.en;
  const titleEl = document.querySelector("title[data-i18n]");
  if (!titleEl) return;
  const key = titleEl.getAttribute("data-i18n");
  const val = dict[key];
  if (typeof val === "string") {
    document.title = val;
  }
}

function applyLanguage(choice) {
  const resolved = choice ? choice : detectLanguage();
  const dict = I18N[resolved] || I18N.en;

  const root = document.documentElement;
  root.setAttribute("data-lang", resolved);
  root.setAttribute("lang", resolved === "zh" ? "zh-CN" : "en");

  for (const el of document.querySelectorAll("[data-i18n]")) {
    const key = el.getAttribute("data-i18n");
    if (!key) continue;
    const val = dict[key];
    if (typeof val !== "string") continue;

    if (el.matches("[data-i18n-html]")) {
      el.innerHTML = val;
    } else {
      el.textContent = val;
    }
  }

  for (const el of document.querySelectorAll("[data-i18n-alt]")) {
    const key = el.getAttribute("data-i18n-alt");
    if (!key) continue;
    const val = dict[key];
    if (typeof val === "string") el.setAttribute("alt", val);
  }

  setTitleI18n(resolved);
  setMetaI18nContent(resolved);

  return resolved;
}

function labelTheme(dict, resolved) {
  const label = dict.theme_label;
  const light = dict.theme_light;
  const dark = dict.theme_dark;

  return `${label}: ${resolved === "dark" ? dark : light}`;
}

function labelLang(dict, resolved) {
  const label = dict.lang_label;
  const zh = dict.lang_zh;
  const en = dict.lang_en;

  return `${label}: ${resolved === "zh" ? zh : en}`;
}

function cycleChoice(current, choices) {
  const idx = Math.max(0, choices.indexOf(current));
  return choices[(idx + 1) % choices.length];
}

function getCurrentDict() {
  const lang = document.documentElement.getAttribute("data-lang");
  return I18N[lang] || I18N.en;
}

function flashMinibuffer(text) {
  const flash = document.getElementById("minibuffer-flash");
  const base = document.getElementById("minibuffer-default");
  if (!flash || !base) return;

  flash.textContent = text;
  flash.hidden = false;
  base.hidden = true;

  window.clearTimeout(flashMinibuffer._t);
  flashMinibuffer._t = window.setTimeout(() => {
    flash.hidden = true;
    base.hidden = false;
  }, 1200);
}

function zoneSymbolForPercent(percent) {
  if (percent >= 75) return "●";
  if (percent >= 50) return "*";
  if (percent >= 25) return ":";
  return "·";
}

function getActiveSectionTitle() {
  if (!document.elementFromPoint) return null;

  const header = document.querySelector(".header-line");
  const headerH = header ? Math.ceil(header.getBoundingClientRect().height) : 0;
  const x = Math.floor(window.innerWidth / 2);
  const y = Math.min(window.innerHeight - 1, headerH + 16);

  const el = document.elementFromPoint(x, y);
  if (!el || !el.closest) return null;

  const section = el.closest("main section[id]");
  if (!section) return null;

  const heading = section.querySelector("h1, h2");
  if (!heading) return null;

  const text = (heading.textContent || "").trim();
  return text || null;
}

function updateReadingStatus() {
  const zoneEl = document.getElementById("mode-line-zone");
  const sectionEl = document.getElementById("mode-line-section");
  const positionEl = document.getElementById("mode-line-position");
  if (!zoneEl && !sectionEl && !positionEl) return;

  const dict = getCurrentDict();
  const doc = document.documentElement;
  const scrollTop = window.scrollY || doc.scrollTop || 0;
  const maxScroll = Math.max(0, doc.scrollHeight - doc.clientHeight);
  const percent = maxScroll ? Math.round((scrollTop / maxScroll) * 100) : 100;

  if (zoneEl) zoneEl.textContent = zoneSymbolForPercent(percent);

  if (positionEl) {
    if (!maxScroll) {
      positionEl.textContent = dict.pos_all || "All";
    } else if (scrollTop <= 0) {
      positionEl.textContent = dict.pos_top || "Top";
    } else if (scrollTop >= maxScroll - 1) {
      positionEl.textContent = dict.pos_bot || "Bot";
    } else {
      positionEl.textContent = `${percent}%`;
    }
  }

  const title = getActiveSectionTitle();
  if (sectionEl && title) {
    sectionEl.textContent = title;
    sectionEl.setAttribute("title", title);
  }
}

function updateEmacsBarsHeight() {
  const bars = document.getElementById("emacs-bars");
  if (!bars) return;

  const h = Math.max(0, Math.ceil(bars.getBoundingClientRect().height));
  if (!h) return;
  document.documentElement.style.setProperty("--emacs-bars-height", `${h}px`);
}

function observeEmacsBarsHeight() {
  const bars = document.getElementById("emacs-bars");
  if (!bars) return;

  updateEmacsBarsHeight();

  if (!window.ResizeObserver) return;
  const ro = new ResizeObserver(() => updateEmacsBarsHeight());
  ro.observe(bars);
}

function scheduleReadingStatusUpdate() {
  if (scheduleReadingStatusUpdate._pending) return;
  scheduleReadingStatusUpdate._pending = true;

  const run = () => {
    scheduleReadingStatusUpdate._pending = false;
    updateReadingStatus();
  };

  if (window.requestAnimationFrame) {
    window.requestAnimationFrame(run);
  } else {
    window.setTimeout(run, 16);
  }
}

function safeStorageGet(key) {
  try {
    return window.localStorage.getItem(key);
  } catch (e) {
    return null;
  }
}

function safeStorageSet(key, value) {
  try {
    window.localStorage.setItem(key, value);
  } catch (e) {
    // Ignore (private mode / disabled storage).
  }
}

function init() {
  const themeBtn = document.getElementById("theme-toggle");
  const langBtn = document.getElementById("lang-toggle");

  if (!themeBtn || !langBtn) return;

  let themeChoice = clampToOptions(
    safeStorageGet(THEME_STORAGE_KEY),
    THEME_CHOICES,
    null,
  );
  let langChoice = clampToOptions(
    safeStorageGet(LANG_STORAGE_KEY),
    LANG_CHOICES,
    null,
  );

  applyTheme(themeChoice);
  const resolvedLang = applyLanguage(langChoice);

  const dict = I18N[resolvedLang] || I18N.en;
  const resolvedTheme = getResolvedTheme(themeChoice);
  themeBtn.textContent = labelTheme(dict, resolvedTheme);
  langBtn.textContent = labelLang(dict, resolvedLang);
  themeBtn.setAttribute("aria-label", themeBtn.textContent);
  langBtn.setAttribute("aria-label", langBtn.textContent);
  observeEmacsBarsHeight();
  updateReadingStatus();

  const darkMql = window.matchMedia
    ? window.matchMedia("(prefers-color-scheme: dark)")
    : null;
  const onSystemThemeChange = () => {
    if (themeChoice) return;
    const newResolved = getResolvedTheme(themeChoice);
    const currentDict =
      I18N[document.documentElement.getAttribute("data-lang")] || I18N.en;
    themeBtn.textContent = labelTheme(currentDict, newResolved);
    themeBtn.setAttribute("aria-label", themeBtn.textContent);
  };

  if (darkMql) {
    if (darkMql.addEventListener) {
      darkMql.addEventListener("change", onSystemThemeChange);
    } else if (darkMql.addListener) {
      darkMql.addListener(onSystemThemeChange);
    }
  }

  themeBtn.addEventListener("click", () => {
    const currentResolved = getResolvedTheme(themeChoice);
    themeChoice = cycleChoice(currentResolved, THEME_CHOICES);
    safeStorageSet(THEME_STORAGE_KEY, themeChoice);
    applyTheme(themeChoice);

    const resolved = getResolvedTheme(themeChoice);
    const currentDict =
      I18N[document.documentElement.getAttribute("data-lang")] || I18N.en;
    themeBtn.textContent = labelTheme(currentDict, resolved);
    themeBtn.setAttribute("aria-label", themeBtn.textContent);
    flashMinibuffer(themeBtn.textContent);
  });

  langBtn.addEventListener("click", () => {
    const currentResolved =
      document.documentElement.getAttribute("data-lang") || detectLanguage();
    langChoice = cycleChoice(currentResolved, LANG_CHOICES);
    safeStorageSet(LANG_STORAGE_KEY, langChoice);

    const resolved = applyLanguage(langChoice);
    const currentDict = I18N[resolved] || I18N.en;

    const resolvedTheme = getResolvedTheme(themeChoice);
    themeBtn.textContent = labelTheme(currentDict, resolvedTheme);
    langBtn.textContent = labelLang(currentDict, resolved);
    themeBtn.setAttribute("aria-label", themeBtn.textContent);
    langBtn.setAttribute("aria-label", langBtn.textContent);
    flashMinibuffer(langBtn.textContent);
    updateReadingStatus();
  });

  window.addEventListener("resize", () => {
    window.clearTimeout(updateEmacsBarsHeight._t);
    updateEmacsBarsHeight._t = window.setTimeout(() => {
      updateEmacsBarsHeight();
      updateReadingStatus();
    }, 80);
  });

  window.addEventListener("scroll", scheduleReadingStatusUpdate);
  window.setTimeout(() => {
    updateEmacsBarsHeight();
    updateReadingStatus();
  }, 0);
}

document.addEventListener("DOMContentLoaded", init);
