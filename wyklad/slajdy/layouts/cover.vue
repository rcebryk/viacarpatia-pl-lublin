<!-- Slajd tytułowy. Treść slajdu (# Tytuł) trafia do dużego pola, frontmatter "subtitle" do dolnego. -->
<script setup lang="ts">
defineProps<{ subtitle?: string }>()
</script>

<template>
  <TemplateFrame class="vc-layout vc-cover">
    <div class="vc-box vc-box-glass" style="left:0; top:141px; width:746px; height:320px" />
    <div class="vc-box vc-box-glass" style="left:0; top:495px; width:746px; height:104px" />
    <div class="vc-cover-title">
      <slot />
    </div>
    <div class="vc-cover-subtitle">
      {{ subtitle }}
    </div>
  </TemplateFrame>
</template>
