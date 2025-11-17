const DATA_PATH = 'data/animals.json';
let animals = [];
let filtered = [];
let selectedCategory = '';
let selectedHabitatType = '';
let catalogMode = false; // whether user entered the catalog from split view
// pagination
let currentPage = 1;
const itemsPerPage = 12;

const paginationEl = document.getElementById('pagination');

const cardsContainer = document.getElementById('cardsContainer');
const searchInput = document.getElementById('searchInput');
const filterHabitat = document.getElementById('filterHabitat');
const sortSelect = document.getElementById('sortSelect');
const showFavsBtn = document.getElementById('showFavsBtn');
const categoriesContainer = document.getElementById('categoriesContainer');
const typeButtonsContainer = document.getElementById('typeButtonsContainer');
const typeIntro = document.getElementById('typeIntro');
const themeToggleBtn = document.getElementById('themeToggleBtn');
const splitView = document.getElementById('splitView');
const returnHomeBtn = document.getElementById('returnHomeBtn');

const detailModalEl = document.getElementById('detailModal');
const detailModal = new bootstrap.Modal(detailModalEl);
const detailTitle = document.getElementById('detailTitle');
const detailImage = document.getElementById('detailImage');
const detailLatin = document.getElementById('detailLatin');
const detailDesc = document.getElementById('detailDesc');
const detailHabitat = document.getElementById('detailHabitat');
const detailSize = document.getElementById('detailSize');
const favToggle = document.getElementById('favToggle');

let currentDetailId = null;

const CONTACT_FORM = document.getElementById('contactForm');

function loadFavorites() {
  try {
    return JSON.parse(localStorage.getItem('favorites') || '[]');
  } catch (e) { return []; }
}

function saveFavorites(list) {
  localStorage.setItem('favorites', JSON.stringify(list));
}

function isFavorited(id) {
  return loadFavorites().includes(id);
}

function toggleFavorite(id) {
  const favs = loadFavorites();
  const idx = favs.indexOf(id);
  if (idx === -1) favs.push(id); else favs.splice(idx, 1);
  saveFavorites(favs);
}

async function fetchData() {
  const res = await fetch(DATA_PATH);
  animals = await res.json();
  // ensure each animal has a numeric strokeCount; if missing, estimate
  animals = animals.map(a => {
    if (a.strokeCount === undefined || a.strokeCount === null) {
      a.strokeCount = estimateStrokeCount(a.name);
    }
    return a;
  });
  filtered = animals.slice();
  populateHabitatFilter();
  renderList();
  // Apply theme from storage or system preference
  initTheme();
}

function populateHabitatFilter() {
  const habitats = Array.from(new Set(animals.map(a => a.habitat))).sort();
  habitats.forEach(h => {
    const o = document.createElement('option');
    o.value = h; o.textContent = h;
    filterHabitat.appendChild(o);
  });
  populateCategoryButtons();
  populateTypeButtons();
}

function populateTypeButtons() {
  if (!typeButtonsContainer) return;
  typeButtonsContainer.innerHTML = '';
  const types = [
    { v: '', label: '全部' },
    { v: 'water', label: '水生' },
    { v: 'land', label: '陸生' }
  ];
  types.forEach(t => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'btn btn-sm btn-outline-primary';
    btn.textContent = t.label;
    btn.dataset.type = t.v;
    btn.addEventListener('click', () => {
      // toggle active
      const prev = typeButtonsContainer.querySelector('.active');
      if (prev) prev.classList.remove('active');
      if (selectedHabitatType === t.v) {
        selectedHabitatType = '';
        btn.classList.remove('active');
        hideTypeIntro();
      } else {
        selectedHabitatType = t.v;
        btn.classList.add('active');
        showTypeIntro(t.v);
      }
      applyFilters();
    });
    typeButtonsContainer.appendChild(btn);
  });
}

function showTypeIntro(type) {
  if (!typeIntro) return;
  let text = '';
  if (type === 'water') {
    text = '水生動物：主要棲息於海洋、河流、湖泊或其他水域，演化出游泳或潛水的能力。點選卡片以查看個別動物介紹。';
  } else if (type === 'land') {
    text = '陸生動物：主要生活在陸地上（森林、草原、沙漠等），以不同方式覓食與移動。點選卡片以查看個別動物介紹。';
  }
  typeIntro.textContent = text;
  typeIntro.classList.remove('d-none');
}

function hideTypeIntro() {
  if (!typeIntro) return;
  typeIntro.classList.add('d-none');
  typeIntro.textContent = '';
}

function populateCategoryButtons() {
  if (!categoriesContainer) return;
  const categories = Array.from(new Set(animals.map(a => a.category || '未分類'))).sort();
  categoriesContainer.innerHTML = '';
  // Add an "全部" pill
  const allBtn = createCategoryPill('', '全部');
  categoriesContainer.appendChild(allBtn);
  // mapping from English category keys to Chinese labels
  const CATEGORY_MAP = {
    'Mammal': '哺乳類',
    'Bird': '鳥類',
    'Reptile': '爬蟲類',
    'Fish': '魚類',
    'Amphibian': '兩棲類',
    'Insect': '昆蟲',
    '未分類': '未分類'
  };
  categories.forEach(cat => {
    const label = CATEGORY_MAP[cat] || cat;
    const btn = createCategoryPill(cat, label);
    categoriesContainer.appendChild(btn);
  });
}

function createCategoryPill(catValue, label) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'btn btn-sm btn-outline-secondary';
  btn.textContent = label;
  btn.dataset.cat = catValue;
  btn.addEventListener('click', (e) => {
    // toggle active
    const prevActive = categoriesContainer.querySelector('.active');
    if (prevActive) prevActive.classList.remove('active');
    if (selectedCategory === catValue) {
      selectedCategory = '';
      btn.classList.remove('active');
    } else {
      selectedCategory = catValue;
      btn.classList.add('active');
    }
    applyFilters();
  });
  return btn;
}

function renderList(list = filtered) {
  cardsContainer.innerHTML = '';
  if (!list.length) {
    cardsContainer.innerHTML = '<div class="col-12 no-results">沒有找到符合的動物</div>';
    if (paginationEl) paginationEl.innerHTML = '';
    return;
  }
  // pagination: calculate total pages and slice the list
  const totalItems = list.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / itemsPerPage));
  if (currentPage > totalPages) currentPage = totalPages;
  const start = (currentPage - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  const pageItems = list.slice(start, end);

  pageItems.forEach((item, idx) => {
    const col = document.createElement('div'); col.className = 'col-12 col-sm-6 col-lg-4';
    const card = document.createElement('div'); card.className = 'card h-100 position-relative fade-in';
    card.setAttribute('data-id', item.id);
    // staggered animation
    card.style.animationDelay = `${idx * 70}ms`;

    const img = document.createElement('img');
    img.src = item.image;
    img.alt = item.name;
    img.className = 'card-img-top';

    const cardBody = document.createElement('div'); cardBody.className = 'card-body';
    const h5 = document.createElement('h5'); h5.className = 'card-title mb-1'; h5.textContent = item.name;
    const p = document.createElement('p'); p.className = 'card-text small text-muted mb-1'; p.textContent = item.latin;
    const info = document.createElement('p'); info.className = 'small mb-0'; info.textContent = `${item.habitat} • 體型指標: ${item.size}`;

    // favorite badge
    const favBtn = document.createElement('button');
    favBtn.className = 'btn btn-sm btn-warning fav-badge';
    favBtn.innerHTML = isFavorited(item.id) ? '★' : '☆';
    favBtn.title = '收藏/取消收藏';
    favBtn.addEventListener('click', (e)=>{
      e.stopPropagation();
      toggleFavorite(item.id);
      favBtn.innerHTML = isFavorited(item.id) ? '★' : '☆';
    });

    cardBody.appendChild(h5); cardBody.appendChild(p); cardBody.appendChild(info);
    card.appendChild(img); card.appendChild(cardBody); card.appendChild(favBtn);

    card.addEventListener('click', ()=> openDetail(item.id));
    col.appendChild(card);
    cardsContainer.appendChild(col);
  });
  // render pagination controls
  renderPagination(totalPages);
}

function renderPagination(totalPages) {
  if (!paginationEl) return;
  paginationEl.innerHTML = '';
  // previous
  const prevLi = document.createElement('li'); prevLi.className = 'page-item' + (currentPage === 1 ? ' disabled' : '');
  const prevBtn = document.createElement('button'); prevBtn.className = 'page-link'; prevBtn.textContent = '上一頁';
  prevBtn.addEventListener('click', ()=> { if (currentPage > 1) { currentPage--; renderList(filtered); } });
  prevLi.appendChild(prevBtn);
  paginationEl.appendChild(prevLi);

  // page numbers (show up to 7 pages centered)
  const maxButtons = 7;
  let startPage = Math.max(1, currentPage - Math.floor(maxButtons/2));
  let endPage = Math.min(totalPages, startPage + maxButtons -1);
  if (endPage - startPage < maxButtons -1) startPage = Math.max(1, endPage - maxButtons +1);
  for (let p = startPage; p <= endPage; p++){
    const li = document.createElement('li'); li.className = 'page-item' + (p === currentPage ? ' active' : '');
    const btn = document.createElement('button'); btn.className = 'page-link'; btn.textContent = String(p);
  btn.addEventListener('click', ()=>{ if (currentPage !== p) { currentPage = p; renderList(filtered); } });
    li.appendChild(btn);
    paginationEl.appendChild(li);
  }

  // next
  const nextLi = document.createElement('li'); nextLi.className = 'page-item' + (currentPage === totalPages ? ' disabled' : '');
  const nextBtn = document.createElement('button'); nextBtn.className = 'page-link'; nextBtn.textContent = '下一頁';
  nextBtn.addEventListener('click', ()=> { if (currentPage < totalPages) { currentPage++; renderList(filtered); } });
  nextLi.appendChild(nextBtn);
  paginationEl.appendChild(nextLi);
}

// THEME: deep color mode (dark) support
function applyThemeClass(theme) {
  if (theme === 'dark') document.body.classList.add('dark');
  else document.body.classList.remove('dark');
  if (themeToggleBtn) {
    const pressed = theme === 'dark' ? 'true' : 'false';
    themeToggleBtn.setAttribute('aria-pressed', pressed);
    themeToggleBtn.textContent = theme === 'dark' ? '淺色模式' : '深色模式';
  }
}

function initTheme() {
  const stored = localStorage.getItem('theme');
  let theme = stored;
  if (!theme) {
    // detect system preference
    const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    theme = prefersDark ? 'dark' : 'light';
  }
  applyThemeClass(theme);
}

if (themeToggleBtn) {
  themeToggleBtn.addEventListener('click', ()=>{
    const isDark = document.body.classList.contains('dark');
    const newTheme = isDark ? 'light' : 'dark';
    applyThemeClass(newTheme);
    localStorage.setItem('theme', newTheme);
  });
}

function openDetail(id) {
  const item = animals.find(a => a.id === id);
  if (!item) return;
  currentDetailId = id;
  detailTitle.textContent = item.name;
  detailLatin.textContent = item.latin;
  detailImage.src = item.image;
  detailDesc.textContent = item.description;
  detailHabitat.textContent = item.habitat;
  detailSize.textContent = item.size;
  favToggle.textContent = isFavorited(id) ? '移除收藏' : '加入收藏';
  detailModal.show();
}

favToggle.addEventListener('click', ()=>{
  if (!currentDetailId) return;
  toggleFavorite(currentDetailId);
  favToggle.textContent = isFavorited(currentDetailId) ? '移除收藏' : '加入收藏';
  renderList();
});

function applyFilters() {
  // whenever filters change, reset to first page
  currentPage = 1;
  const q = searchInput.value.trim().toLowerCase();
  const habitat = filterHabitat.value;
  const sort = sortSelect.value;
  filtered = animals.filter(a => {
    const matchQ = !q || a.name.toLowerCase().includes(q) || a.latin.toLowerCase().includes(q) || a.description.toLowerCase().includes(q);
    const matchH = !habitat || a.habitat === habitat;
    const matchC = !selectedCategory || (a.category === selectedCategory);
    // habitat type filter: if selectedHabitatType is 'water', include water or both; if 'land', include land or both
    let matchType = true;
    if (selectedHabitatType === 'water') matchType = (a.habitatType === 'water' || a.habitatType === 'both');
    else if (selectedHabitatType === 'land') matchType = (a.habitatType === 'land' || a.habitatType === 'both');
    return matchQ && matchH && matchC && matchType;
  });
  if (sort === 'name') filtered.sort((a,b)=> a.name.localeCompare(b.name));
  else if (sort === 'size') filtered.sort((a,b)=> b.size - a.size);
  else if (sort === 'stroke-est' || sort === 'stroke') {
    // use the concrete strokeCount field (fallback to estimated when missing)
    filtered.sort((a,b)=> (a.strokeCount || estimateStrokeCount(a.name)) - (b.strokeCount || estimateStrokeCount(b.name)));
  }
  renderList();
}

searchInput.addEventListener('input', ()=> applyFilters());
filterHabitat.addEventListener('change', ()=> applyFilters());
sortSelect.addEventListener('change', ()=> applyFilters());

showFavsBtn.addEventListener('click', ()=>{
  const favs = loadFavorites();
  if (showFavsBtn.dataset.showing === '1') {
    // restore
    showFavsBtn.textContent = '顯示收藏';
    showFavsBtn.dataset.showing = '0';
    filtered = animals.slice();
    currentPage = 1;
    applyFilters();
  } else {
    showFavsBtn.textContent = '顯示全部';
    showFavsBtn.dataset.showing = '1';
    filtered = animals.filter(a => favs.includes(a.id));
    currentPage = 1;
    renderList();
  }
});

// contact form validation (Constraint Validation API)
CONTACT_FORM.addEventListener('submit', (e) => {
  if (!CONTACT_FORM.checkValidity()) {
    e.preventDefault();
    e.stopPropagation();
  } else {
    e.preventDefault();
    // 簡單示意：不送出到 server，顯示成功訊息
    alert('感謝您的訊息，已收到（本範例不會實際送出）。');
    CONTACT_FORM.reset();
  }
  CONTACT_FORM.classList.add('was-validated');
});

// 初始載入
fetchData().catch(err => {
  console.error('載入資料失敗', err);
  cardsContainer.innerHTML = '<div class="col-12 no-results">載入資料失敗，請稍後再試。</div>';
});

// convert name to an estimated stroke count (heuristic)
function estimateStrokeCount(name) {
  if (!name) return 0;
  // small lookup for common characters to improve ordering (extendable)
  const map = {
    '獅': 13,'子':3,'大':3,'象':12,'長':8,'頸':12,'鹿':11,'熊':14,'貓':11,'無':12,'尾':7,
    '企':6,'鵝':16,'白':5,'頭':9,'海':10,'鵰':18,'赤':7,'狐':7,'老':6,'虎':8,'灰':6,'狼':10,
    '河':8,'馬':10,'袋':14,'斑':9,'鱷':18,'蜂':13,'鳥':11,'鯨':15,'鯊':11,'魚':11,'鮭':11,
    '火':4,'烈':10,'鸚':17,'鵡':14,'科':8,'莫':10,'多':6,'巨':5,'蜥':13,'短':12,'吻':7,'龜':16,'蛇':11,'青':8,'蛙':9,'蠑':16,'螈':16,'蝴':15,'蝶':15,'蜜':14
  };
  let total = 0;
  for (const ch of name) {
    if (map[ch] !== undefined) total += map[ch];
    else if (/\p{Script=Han}/u.test(ch)) total += 10; // fallback for CJK characters
    else total += 1; // latin or punctuation
  }
  return total;
}

// Split view interactions: clicking left/right enters catalog filtered by habitat type
function initSplitView() {
  if (!splitView) return;
  const halves = splitView.querySelectorAll('.split.half');
  halves.forEach(h => {
    h.addEventListener('click', () => {
      const t = h.dataset.type;
      enterCatalogFromSplit(t);
    });
    h.addEventListener('keypress', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        const t = h.dataset.type;
        enterCatalogFromSplit(t);
      }
    });
  });
}

function enterCatalogFromSplit(type) {
  // hide split, show catalog (main container is already in page)
  if (splitView) splitView.classList.add('hidden');
  catalogMode = true;
  // reveal catalog main & footer which were hidden on initial load
  const mainEl = document.getElementById('catalogMain');
  const footerEl = document.getElementById('catalogFooter');
  if (mainEl) mainEl.classList.remove('d-none');
  if (footerEl) footerEl.classList.remove('d-none');
  // show return-home button
  if (returnHomeBtn) returnHomeBtn.classList.remove('d-none');
  // set selected habitat type and show intro text
  selectedHabitatType = type;
  if (type === 'land') showTypeIntro('land');
  else if (type === 'water') showTypeIntro('water');
  // set sort to stroke-est (estimated筆畫) if available
  if (sortSelect) {
    const opt = document.createElement('option');
    opt.value = 'stroke-est';
    opt.textContent = '依筆畫（估算）';
    // avoid duplicating option
    if (!Array.from(sortSelect.options).some(o => o.value === 'stroke-est')) sortSelect.appendChild(opt);
    sortSelect.value = 'stroke-est';
  }
  applyFilters();
  // scroll to main content
  const main = document.querySelector('main');
  if (main) main.scrollIntoView({ behavior: 'smooth' });
}

function returnToHome() {
  // show split, hide catalog
  if (splitView) splitView.classList.remove('hidden');
  const mainEl = document.getElementById('catalogMain');
  const footerEl = document.getElementById('catalogFooter');
  if (mainEl) mainEl.classList.add('d-none');
  if (footerEl) footerEl.classList.add('d-none');
  // hide return button
  if (returnHomeBtn) returnHomeBtn.classList.add('d-none');
  // reset state
  catalogMode = false;
  selectedHabitatType = '';
  hideTypeIntro();
  // clear category active
  const prevCat = categoriesContainer && categoriesContainer.querySelector('.active');
  if (prevCat) prevCat.classList.remove('active');
  // clear type active
  if (typeButtonsContainer) {
    const prevType = typeButtonsContainer.querySelector('.active');
    if (prevType) prevType.classList.remove('active');
  }
  // reset sort to default 'name'
  if (sortSelect) sortSelect.value = 'name';
  filtered = animals.slice();
  currentPage = 1;
  renderList();
  // scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// initialize split view after DOM and data ready
document.addEventListener('DOMContentLoaded', () => initSplitView());
// also call after fetch to ensure split exists
initSplitView();
if (returnHomeBtn) returnHomeBtn.addEventListener('click', returnToHome);
// Expose minimal globals for debugging
window.__animals = animals;
