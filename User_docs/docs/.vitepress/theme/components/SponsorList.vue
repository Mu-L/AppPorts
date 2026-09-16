<script setup>
import { computed } from "vue";

import data from "../../../../../sponsors.json";

const props = defineProps({
  locale: { type: String, default: "zh-Hans" },
});

const labels = {
  "zh-Hans": { name: "昵称", amount: "金额", link: "链接" },
  "zh-Hant": { name: "暱稱", amount: "金額", link: "連結" },
  en: { name: "Nickname", amount: "Amount", link: "Link" },
  ja: { name: "ニックネーム", amount: "金額", link: "リンク" },
  ko: { name: "닉네임", amount: "금액", link: "링크" },
  de: { name: "Name", amount: "Betrag", link: "Link" },
  fr: { name: "Pseudonyme", amount: "Montant", link: "Lien" },
  es: { name: "Apodo", amount: "Importe", link: "Enlace" },
};

const text = computed(() => labels[props.locale] ?? labels["zh-Hans"]);

const numberFormat = computed(
  () =>
    new Intl.NumberFormat(props.locale, {
      style: "currency",
      currency: data.currency ?? "CNY",
      maximumFractionDigits: 0,
    }),
);

const sponsors = computed(() =>
  [...(data.sponsors ?? [])].sort(
    (a, b) =>
      (b.amount ?? 0) - (a.amount ?? 0) || String(a.date ?? "").localeCompare(String(b.date ?? "")),
  ),
);
</script>

<template>
  <table>
    <thead>
      <tr>
        <th>{{ text.name }}</th>
        <th>{{ text.amount }}</th>
        <th>{{ text.link }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="sponsor in sponsors" :key="sponsor.link || sponsor.name">
        <td>{{ sponsor.name }}</td>
        <td>{{ numberFormat.format(sponsor.amount ?? 0) }}</td>
        <td>
          <a v-if="sponsor.link" :href="sponsor.link" target="_blank" rel="noopener noreferrer">{{ sponsor.link }}</a>
          <span v-else>—</span>
        </td>
      </tr>
    </tbody>
  </table>
</template>
