<!--
  Dwie kolumny pod pasem tytułu (układ "Dwa elementy zawartości").
  Lewa kolumna: zwykła treść slajdu; prawa: wszystko po znaczniku ::right::
-->
<template>
  <TemplateFrame class="vc-layout vc-content vc-two-cols">
    <div class="vc-box vc-box-glass" style="left:0; top:138px; width:1280px; height:72px" />
    <div class="vc-content-body">
      <div class="vc-col">
        <slot />
      </div>
      <div class="vc-col">
        <slot name="right" />
      </div>
    </div>
  </TemplateFrame>
</template>
