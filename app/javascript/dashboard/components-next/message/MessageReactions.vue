<script setup>
import { computed } from 'vue';
import { useMessageContext } from './provider.js';

const { contentAttributes } = useMessageContext();

const reactionEntries = computed(() => {
  const reactions = contentAttributes.value?.reactions || {};
  return Object.values(reactions).filter(reaction => reaction?.emoji);
});

const reactionGroups = computed(() => {
  const groups = reactionEntries.value.reduce((result, reaction) => {
    const emoji = reaction.emoji;
    if (!emoji) return result;

    const actorName = reaction.actorName || reaction.actor_name;

    if (!result[emoji]) {
      result[emoji] = {
        emoji,
        count: 0,
        names: [],
      };
    }

    result[emoji].count += 1;
    if (actorName && !result[emoji].names.includes(actorName)) {
      result[emoji].names.push(actorName);
    }

    return result;
  }, {});

  return Object.values(groups).map(group => ({
    ...group,
    tooltip: group.names.join(', '),
  }));
});
</script>

<template>
  <div v-show="reactionGroups.length" class="flex flex-wrap gap-1 text-xs">
    <div
      v-for="group in reactionGroups"
      :key="group.emoji"
      :title="group.tooltip || undefined"
      class="inline-flex items-center gap-1 rounded-full bg-n-alpha-black2 px-2 py-1 text-n-slate-12"
    >
      <span>{{ group.emoji }}</span>
      <span>{{ group.count }}</span>
    </div>
  </div>
</template>
