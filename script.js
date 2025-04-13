/**********************************************
 * Tidslinjelogik för vårt klassiska intro
 **********************************************/
window.addEventListener("load", async () => {
  // Kör igång hela sekvensen efter att sidan laddat
  // 1) Intro-text (blå) är redan styrd av CSS (5s)
  // 2) Sedan Star Wars-logo i djupet
  // 3) Sedan crawl
  // 4) Sedan planet
  await sleep(5000); // Vänta tills intro-text är färdig (5s)

  // Visa logon och starta dess animation
  const logo = document.getElementById("logo");
  logo.style.display = "block";
  logo.style.opacity = 1;

  // Samtidigt starta musiken om du vill
  const bgMusic = document.getElementById("bgMusic");
  try { await bgMusic.play(); } catch (err) { console.log("Kan ej starta musik:", err); }

  await sleep(4000); // Logon tar 4s på sig att försvinna

  // Visa crawl
  const crawlContainer = document.getElementById("crawl-container");
  crawlContainer.style.display = "block";
  await sleep(20000); // Crawl varar ca 20s

  // Ta bort crawl-container
  crawlContainer.style.display = "none";

  // Visa planet (kamerapanorering) – trigga dess animation
  const planet = document.getElementById("planet-effect");
  planet.style.display = "block";

  await sleep(4000); 
  // ...Klar! Du kan om du vill lägga in fler steg, t.ex.
  // fade to black, rymdskepp som sveper in, etc.
});

/**********************************************
 * Helper: sleep
 **********************************************/
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
