<!--
  Slajd końcowy: treść (np. kontakt) w dużym polu, frontmatter "subtitle"
  w dolnym lewym polu, "thanks" w prawym (domyślnie „Dziękuję za uwagę”).
-->
<script setup lang="ts">
withDefaults(defineProps<{ subtitle?: string, thanks?: string }>(), {
  thanks: 'Dziękuję za uwagę',
})
</script>

<template>
  <TemplateFrame class="vc-layout vc-end">
    <div class="vc-box vc-box-glass" style="left:0; top:141px; width:746px; height:320px" />
    <div class="vc-box vc-box-glass" style="left:0; top:495px; width:746px; height:104px" />
    <div class="vc-box vc-box-solid" style="left:746px; top:495px; width:526px; height:104px" />
    <div class="vc-cover-title">
      <slot />
    </div>
    <div class="vc-cover-subtitle">
      {{ subtitle }}
    </div>
    <div class="vc-thanks">
      {{ thanks }}
    </div>
  </TemplateFrame>
</template>
