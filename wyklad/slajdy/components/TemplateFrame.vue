<!--
  Rama szablonu "Politechniczna Sieć VIA CARPATIA" (odtworzona z pliku .pptx):
  tło z grafiką sieci, biały pasek z logo u góry, biały pasek z logo
  ministerstwa i informacją o finansowaniu u dołu.
  Współrzędne w px na płótnie 1280×720 (canvasWidth: 1280).
-->
<script setup lang="ts">
import { useSlideContext } from '@slidev/client'

const { $page } = useSlideContext()
</script>

<template>
  <div class="vc-frame">
    <slot />

    <header class="vc-header">
      <img class="vc-logo-vc" src="/szablon/logo-via-carpatia.jpg" alt="Politechniczna Sieć VIA CARPATIA">
      <img class="vc-logo-uczelnie" src="/szablon/logo-uczelnie.png" alt="Politechnika Białostocka, Politechnika Lubelska, Politechnika Rzeszowska">
    </header>

    <footer class="vc-footer">
      <img class="vc-min vc-min-l" src="/szablon/logo-ministerstwo.png" alt="Minister Nauki i Szkolnictwa Wyższego">
      <p class="vc-funding">
        Zadanie finansowane w ramach zlecenia<br>
        Ministra Nauki i Szkolnictwa Wyższego<br>
        pod nazwą „Politechniczna Sieć VIA CARPATIA” edycja II<br>
        w latach 2026-2030, kwota finansowania 9 977 000 zł
      </p>
      <img class="vc-min vc-min-r" src="/szablon/logo-ministerstwo.png" alt="Minister Nauki i Szkolnictwa Wyższego">
      <span class="vc-page">{{ $page }}</span>
    </footer>
  </div>
</template>
