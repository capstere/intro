# Så här funkar det steg för steg
      1.    När sidan laddas (window.load) körs vår sekvens i script.js.
      2.    Blå text “A long time ago…” syns & fade:ar ut under 5 sek (helt i CSS).
      3.    Star Wars-logga visas och “flyger bort” i djupet på 4 sek, samtidigt startar musiken.
      4.    Crawl sektionen visas och texten rullar uppåt under 20 sek.
      5.    Planet glider upp underifrån (som en kamerapanorering nedåt), på 4 sek.
      6.    Klart – du kan lägga till valfritt efteråt (ex. rymdskepp som sveper in).

Allt är designat för att motsvara originalet:
      •     Den blå texten (klassisk)
      •     Loggan som rör sig bort i rymden
      •     Crawlern i 3D-perspektiv
      •     Kamerapanorering nedåt (här simulerad genom att planet kommer nedifrån)

Vill du lägga till:
      •     Ljudknappar, lasers, en Star Destroyer som sveper in uppifrån – inga problem. Lägg det i HTML (knappar / bilder) och styr via script.js och CSS-animation.

⸻

Tips & finjusteringar
      1.    Justera tider i script.js och @keyframes crawl för att få exakt rätt tempo.
      2.    Använd gärna en riktig Star Wars-font (t.ex. via Google Fonts) för ännu mer känsla.
      3.    Mobilwebbläsare kan kräva “user interaction” (klick) för att starta ljud.
      4.    Vill du ha fade to black i slutet? Lägg en <div id="fadeout"></div> som tar över skärmen med en animation “opacity: 0 -> 1”.
