// Fabled Kingdoms Landing Page Interactions

document.addEventListener('DOMContentLoaded', () => {
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
