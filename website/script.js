const menuBar = document.querySelector(".menu-bar");
const toggle = document.querySelector(".barkeep-toggle");
const reset = document.querySelector(".demo-reset");
const message = document.querySelector(".demo-message");

function setCollapsed(collapsed) {
  menuBar.classList.toggle("is-collapsed", collapsed);
  toggle.setAttribute("aria-expanded", String(!collapsed));
  toggle.setAttribute(
    "aria-label",
    collapsed ? "Reveal managed menu bar icons" : "Hide managed menu bar icons",
  );
  toggle.querySelector("span").textContent = collapsed ? "››" : "‹‹";
  message.querySelector("strong").textContent = collapsed
    ? "That’s better."
    : "Click the chevrons.";
  message.querySelector("span:last-child").textContent = collapsed
    ? "Five icons gone. Your apps are still right where you left them."
    : "Five icons disappear. None are harmed.";
}

toggle.addEventListener("click", () => {
  setCollapsed(!menuBar.classList.contains("is-collapsed"));
});

reset.addEventListener("click", () => setCollapsed(false));

document.addEventListener("keydown", (event) => {
  if (event.altKey && event.metaKey && event.key.toLowerCase() === "b") {
    event.preventDefault();
    setCollapsed(!menuBar.classList.contains("is-collapsed"));
  }
});

const revealObserver = new IntersectionObserver(
  (entries, observer) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    }
  },
  { threshold: 0.12 },
);

document.querySelectorAll(".reveal").forEach((element) => revealObserver.observe(element));
