// Fabled Kingdoms Landing Page Interactions

// --- Internationalization (i18n) ---
const translations = {
  en: {
    page_title: "Fabled Kingdoms | Multiplayer Fantasy RPG",
    nav_features: "Features",
    nav_multiplayer: "Multiplayer",
    nav_download: "Download Now",
    hero_subtitle: "A Procedural Dark Fantasy RPG built with Godot 4.",
    hero_description: "Explore endless procedurally generated dark forests, battle fearsome enemies, and team up with friends anywhere in the world using native Steam P2P multiplayer. No servers required.",
    btn_download: "Download for Windows",
    version_info: "Version 0.1 Alpha • 45 MB",
    feat_1_title: "🌍 Procedural Worlds",
    feat_1_desc: "Every playthrough generates a unique dark forest with dynamic terrain, rivers, and mysterious towns.",
    feat_2_title: "⚔️ Action Combat",
    feat_2_desc: "Engage in fluid stamina-based combat. Dodge, parry, and cast powerful water magic against dynamic enemy AI.",
    feat_3_title: "🤝 Seamless Co-op",
    feat_3_desc: "Built-in Steam integration. Host a game and share your secret Lobby Code for instant peer-to-peer multiplayer.",
    footer_copy: "&copy; 2026 Fabled Kingdoms. Built with Godot 4.",
    footer_created: "Created by"
  },
  es: {
    page_title: "Fabled Kingdoms | RPG de Fantasía Multijugador",
    nav_features: "Características",
    nav_multiplayer: "Multijugador",
    nav_download: "Descargar Ahora",
    hero_subtitle: "Un RPG de Fantasía Oscura Procedural hecho en Godot 4.",
    hero_description: "Explora infinitos bosques oscuros generados proceduralmente, lucha contra temibles enemigos y juega en cooperativo con amigos en cualquier lugar del mundo usando el modo P2P nativo de Steam. Sin necesidad de servidores.",
    btn_download: "Descargar para Windows",
    version_info: "Versión 0.1 Alpha • 45 MB",
    feat_1_title: "🌍 Mundos Procedurales",
    feat_1_desc: "Cada partida genera un bosque oscuro único con terrenos dinámicos, ríos y pueblos misteriosos.",
    feat_2_title: "⚔️ Combate de Acción",
    feat_2_desc: "Participa en un combate fluido basado en aguante. Esquiva, haz parrys y lanza poderosa magia de agua contra una IA enemiga dinámica.",
    feat_3_title: "🤝 Cooperativo Inmediato",
    feat_3_desc: "Integración nativa con Steam. Crea una partida y comparte tu Código de Sala secreto para jugar en multijugador P2P instantáneo.",
    footer_copy: "&copy; 2026 Fabled Kingdoms. Creado con Godot 4.",
    footer_created: "Creado por"
  }
};

type Language = 'en' | 'es';

function setLanguage(lang: Language) {
  // Save preference
  localStorage.setItem('fk_lang', lang);
  
  // Update document language
  document.documentElement.lang = lang;

  // Update DOM elements
  const elements = document.querySelectorAll('[data-i18n]');
  elements.forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (key && translations[lang][key as keyof typeof translations['en']]) {
      el.innerHTML = translations[lang][key as keyof typeof translations['en']];
    }
  });

  // Update button states
  document.getElementById('btn-en')?.classList.toggle('active', lang === 'en');
  document.getElementById('btn-es')?.classList.toggle('active', lang === 'es');
}

// Initialize language on load
function initLanguage() {
  // Check local storage first
  const savedLang = localStorage.getItem('fk_lang') as Language;
  if (savedLang && (savedLang === 'en' || savedLang === 'es')) {
    setLanguage(savedLang);
    return;
  }

  // Auto-detect from browser
  const browserLang = navigator.language.toLowerCase();
  if (browserLang.startsWith('es')) {
    setLanguage('es');
  } else {
    setLanguage('en');
  }
}

// --- Interaction logic ---
document.addEventListener('DOMContentLoaded', () => {
  // Initialize i18n
  initLanguage();

  // Bind language buttons
  document.getElementById('btn-en')?.addEventListener('click', () => setLanguage('en'));
  document.getElementById('btn-es')?.addEventListener('click', () => setLanguage('es'));

  // 1. Intersection Observer for fade-in elements
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  // Observe the features grid
  const featuresGrid = document.querySelector('.features-grid');
  if (featuresGrid) {
    observer.observe(featuresGrid);
  }

  // 2. Dynamic mouse glow effect on glass cards
  const cards = document.querySelectorAll('.feature-card');
  
  cards.forEach(card => {
    card.addEventListener('mousemove', (e) => {
      const mouseEvent = e as MouseEvent;
      const rect = card.getBoundingClientRect();
      const x = mouseEvent.clientX - rect.left;
      const y = mouseEvent.clientY - rect.top;
      
      // Update custom properties for a radial gradient glow following the mouse
      (card as HTMLElement).style.setProperty('--mouse-x', `${x}px`);
      (card as HTMLElement).style.setProperty('--mouse-y', `${y}px`);
    });
  });
});
