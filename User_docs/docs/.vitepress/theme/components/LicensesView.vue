<script setup>
import { computed } from "vue";

const props = defineProps({
  locale: { type: String, default: "zh-Hans" },
});

const groups = {
  own: [
    {
      name: "AppPorts",
      license: "Apache License 2.0",
      link: "https://github.com/wzh4869/AppPorts/blob/main/LICENSE",
    },
  ],
  third: [
    {
      key: "pearcleaner",
      name: "Pearcleaner",
      license: "Apache-2.0 with Commons Clause",
      link: "https://github.com/alienator88/Pearcleaner",
    },
  ],
  docs: [
    {
      key: "vitepress",
      name: "VitePress",
      license: "MIT",
      link: "https://github.com/vuejs/vitepress",
    },
    {
      key: "vue",
      name: "Vue.js",
      license: "MIT",
      link: "https://github.com/vuejs/core",
    },
    {
      key: "teek",
      name: "vitepress-theme-teek",
      license: "MIT",
      link: "https://github.com/Kele-Bingtang/vitepress-theme-teek",
    },
    {
      key: "sass",
      name: "Sass",
      license: "MIT",
      link: "https://github.com/sass/dart-sass",
    },
    {
      key: "inter",
      name: "Inter",
      license: "SIL OFL 1.1",
      link: "https://github.com/rsms/inter",
    },
  ],
  assets: [
    { key: "appIcon", name: "AppPorts", license: "Apache-2.0" },
    { key: "sfSymbols", name: "SF Symbols", license: "Apple" },
    { key: "interFont", name: "Inter", license: "SIL OFL 1.1" },
    { key: "teekIconfont", name: "teek iconfont", license: "MIT" },
  ],
};

const text = {
  "zh-Hans": {
    lead: "AppPorts 的实现离不开这些优秀的开源项目，在此向每一位作者与贡献者致谢。",
    sections: { own: "本项目", third: "参考与使用的第三方项目", docs: "文档站使用的开源项目", assets: "图标与字体" },
    view: "查看",
    meta: {
      pearcleaner: "目录体积扫描等实现参考，许可证附带 Commons Clause 条件",
      vitepress: "文档站框架，随包分发 Inter 字体",
      vue: "前端框架",
      teek: "站点主题与图标字体",
      sass: "仅构建期使用，不随站点分发",
      inter: "文档站正文字体，由 VitePress 提供",
      appIcon: "项目自制的应用图标",
      sfSymbols: "应用内图标，由 macOS 提供，遵循 Apple 的 SF Symbols 使用条款",
      interFont: "文档站正文字体",
      teekIconfont: "文档站图标字体，随主题分发",
    },
    notices: [
      {
        title: "Pearcleaner 的附加条件",
        body: "Pearcleaner 以 Apache 2.0 with Commons Clause 发布，这是源码可见的 fair-code 许可，并非 OSI 认可的开源许可。除 Apache 2.0 条款外，它还禁止「销售」以该软件功能为主要价值的产品或服务。使用时需一并保留许可证全文，其中包括：",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  "zh-Hant": {
    lead: "AppPorts 的實作離不開這些優秀的開源專案，在此向每一位作者與貢獻者致謝。",
    sections: { own: "本專案", third: "參考與使用的第三方專案", docs: "文件站使用的開源專案", assets: "圖示與字型" },
    view: "檢視",
    meta: {
      pearcleaner: "目錄體積掃描等實作參考，授權附帶 Commons Clause 條件",
      vitepress: "文件站框架，隨套件分發 Inter 字型",
      vue: "前端框架",
      teek: "站點主題與圖示字型",
      sass: "僅建置期使用，不隨站點分發",
      inter: "文件站正文字型，由 VitePress 提供",
      appIcon: "專案自製的應用程式圖示",
      sfSymbols: "應用程式內圖示，由 macOS 提供，遵循 Apple 的 SF Symbols 使用條款",
      interFont: "文件站正文字型",
      teekIconfont: "文件站圖示字型，隨主題分發",
    },
    notices: [
      {
        title: "Pearcleaner 的附加條件",
        body: "Pearcleaner 以 Apache 2.0 with Commons Clause 發布，這是原始碼可見的 fair-code 授權，並非 OSI 認可的開源授權。除 Apache 2.0 條款外，它還禁止「銷售」以該軟體功能為主要價值的產品或服務。使用時需一併保留授權全文，其中包括：",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  en: {
    lead: "AppPorts is built on the shoulders of these excellent open source projects. Thanks to every author and contributor.",
    sections: { own: "This project", third: "Third-party projects", docs: "Documentation site", assets: "Icons and fonts" },
    view: "View",
    meta: {
      pearcleaner: "Reference for directory size scanning; the license adds a Commons Clause condition",
      vitepress: "Documentation framework; ships the Inter font",
      vue: "Frontend framework",
      teek: "Site theme and icon font",
      sass: "Build-time only, not distributed",
      inter: "Body font of the site, provided by VitePress",
      appIcon: "App icon made by the project",
      sfSymbols: "In-app icons provided by macOS, subject to Apple's SF Symbols terms",
      interFont: "Body font of the site",
      teekIconfont: "Icon font of the site, distributed with the theme",
    },
    notices: [
      {
        title: "Additional condition in Pearcleaner",
        body: "Pearcleaner is released under Apache 2.0 with Commons Clause — a source-available \"fair-code\" license that is not an OSI-approved open source license. On top of the Apache 2.0 terms it forbids “Selling” a product or service whose value derives substantially from the software. Keep the full license text, which includes:",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  ja: {
    lead: "AppPorts はこれらの優れたオープンソースプロジェクトの上に成り立っています。作者と貢献者の皆さまに感謝します。",
    sections: { own: "本プロジェクト", third: "参考・利用しているサードパーティ", docs: "ドキュメントサイト", assets: "アイコンとフォント" },
    view: "表示",
    meta: {
      pearcleaner: "ディレクトリ容量スキャンなどの実装参考。ライセンスに Commons Clause 条件が付きます",
      vitepress: "ドキュメントのフレームワーク。Inter フォントを同梱",
      vue: "フロントエンドフレームワーク",
      teek: "サイトテーマとアイコンフォント",
      sass: "ビルド時のみ使用、配布物には含まれません",
      inter: "サイト本文のフォント。VitePress が提供",
      appIcon: "プロジェクト自作のアプリアイコン",
      sfSymbols: "アプリ内アイコン。macOS が提供し、Apple の SF Symbols 利用条件に従います",
      interFont: "サイト本文のフォント",
      teekIconfont: "サイトのアイコンフォント。テーマとともに配布",
    },
    notices: [
      {
        title: "Pearcleaner の追加条件",
        body: "Pearcleaner は Apache 2.0 with Commons Clause で公開されています。これはソース公開型の fair-code ライセンスで、OSI 承認のオープンソースライセンスではありません。Apache 2.0 の条件に加えて、本ソフトウェアの機能を主要な価値とする製品・サービスの「販売」を禁じています。利用時は以下を含むライセンス全文を保持してください。",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  ko: {
    lead: "AppPorts는 이 훌륭한 오픈 소스 프로젝트들 위에 만들어졌습니다. 모든 작성자와 기여자에게 감사드립니다.",
    sections: { own: "이 프로젝트", third: "참고 및 사용한 서드파티", docs: "문서 사이트", assets: "아이콘과 글꼴" },
    view: "보기",
    meta: {
      pearcleaner: "디렉터리 용량 스캔 등 구현 참고, 라이선스에 Commons Clause 조건이 붙습니다",
      vitepress: "문서 프레임워크, Inter 글꼴 동봉",
      vue: "프런트엔드 프레임워크",
      teek: "사이트 테마와 아이콘 글꼴",
      sass: "빌드 시에만 사용, 배포물에 미포함",
      inter: "사이트 본문 글꼴, VitePress 제공",
      appIcon: "프로젝트에서 직접 만든 앱 아이콘",
      sfSymbols: "앱 내부 아이콘, macOS 제공, Apple의 SF Symbols 이용 약관 적용",
      interFont: "사이트 본문 글꼴",
      teekIconfont: "사이트 아이콘 글꼴, 테마와 함께 배포",
    },
    notices: [
      {
        title: "Pearcleaner의 추가 조건",
        body: "Pearcleaner는 Apache 2.0 with Commons Clause로 배포됩니다. 이는 소스 공개형 fair-code 라이선스이며 OSI가 승인한 오픈 소스 라이선스가 아닙니다. Apache 2.0 조건에 더해 이 소프트웨어의 기능이 주요 가치인 제품이나 서비스를 ‘판매’하는 것을 금지합니다. 사용 시 다음을 포함한 라이선스 전문을 유지하세요.",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  de: {
    lead: "AppPorts steht auf den Schultern dieser hervorragenden Open-Source-Projekte. Danke an alle Autorinnen, Autoren und Mitwirkenden.",
    sections: { own: "Dieses Projekt", third: "Verwendete Fremdprojekte", docs: "Dokumentationsseite", assets: "Symbole und Schriften" },
    view: "Ansehen",
    meta: {
      pearcleaner: "Referenz für die Verzeichnisgrößen-Analyse; die Lizenz enthält eine Commons-Clause-Bedingung",
      vitepress: "Dokumentations-Framework, liefert die Schrift Inter mit",
      vue: "Frontend-Framework",
      teek: "Theme und Icon-Font der Seite",
      sass: "Nur zur Build-Zeit, nicht Teil der Auslieferung",
      inter: "Textschrift der Seite, bereitgestellt von VitePress",
      appIcon: "Vom Projekt erstelltes App-Symbol",
      sfSymbols: "Symbole in der App, von macOS bereitgestellt, es gelten Apples SF-Symbols-Bedingungen",
      interFont: "Textschrift der Seite",
      teekIconfont: "Icon-Font der Seite, wird mit dem Theme verteilt",
    },
    notices: [
      {
        title: "Zusatzbedingung bei Pearcleaner",
        body: "Pearcleaner steht unter Apache 2.0 with Commons Clause – einer quelloffenen „Fair-Code\"-Lizenz, die keine von der OSI anerkannte Open-Source-Lizenz ist. Zusätzlich zu den Apache-2.0-Bedingungen verbietet sie den „Verkauf\" eines Produkts oder Dienstes, dessen Wert wesentlich auf dieser Software beruht. Der vollständige Lizenztext muss erhalten bleiben, einschließlich:",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  fr: {
    lead: "AppPorts s'appuie sur ces excellents projets open source. Merci à toutes les personnes qui les écrivent et les maintiennent.",
    sections: { own: "Ce projet", third: "Projets tiers utilisés", docs: "Site de documentation", assets: "Icônes et polices" },
    view: "Voir",
    meta: {
      pearcleaner: "Référence pour l'analyse de la taille des dossiers ; la licence ajoute une condition Commons Clause",
      vitepress: "Framework du site, fournit la police Inter",
      vue: "Framework frontend",
      teek: "Thème du site et police d'icônes",
      sass: "Utilisé uniquement à la compilation, non distribué",
      inter: "Police du corps de texte, fournie par VitePress",
      appIcon: "Icône de l'app réalisée par le projet",
      sfSymbols: "Icônes dans l'app, fournies par macOS, soumises aux conditions SF Symbols d'Apple",
      interFont: "Police du corps de texte du site",
      teekIconfont: "Police d'icônes du site, distribuée avec le thème",
    },
    notices: [
      {
        title: "Condition supplémentaire de Pearcleaner",
        body: "Pearcleaner est publié sous Apache 2.0 with Commons Clause, une licence « fair-code » à code source disponible, qui n'est pas une licence open source reconnue par l'OSI. En plus des conditions d'Apache 2.0, elle interdit de « vendre » un produit ou service dont la valeur repose substantiellement sur ce logiciel. Le texte complet de la licence doit être conservé, y compris :",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
  es: {
    lead: "AppPorts se apoya en estos excelentes proyectos de código abierto. Gracias a todas las personas que los mantienen.",
    sections: { own: "Este proyecto", third: "Proyectos de terceros utilizados", docs: "Sitio de documentación", assets: "Iconos y fuentes" },
    view: "Ver",
    meta: {
      pearcleaner: "Referencia para el análisis del tamaño de carpetas; la licencia añade una condición Commons Clause",
      vitepress: "Framework del sitio; incluye la fuente Inter",
      vue: "Framework de frontend",
      teek: "Tema del sitio y fuente de iconos",
      sass: "Solo en tiempo de compilación, no se distribuye",
      inter: "Fuente del cuerpo del sitio, la aporta VitePress",
      appIcon: "Icono de la app creado por el proyecto",
      sfSymbols: "Iconos de la app proporcionados por macOS, sujetos a las condiciones de SF Symbols de Apple",
      interFont: "Fuente del cuerpo del sitio",
      teekIconfont: "Fuente de iconos del sitio, distribuida con el tema",
    },
    notices: [
      {
        title: "Condición adicional de Pearcleaner",
        body: "Pearcleaner se publica bajo Apache 2.0 with Commons Clause, una licencia «fair-code» de código disponible que no está aprobada por la OSI como código abierto. Además de las condiciones de Apache 2.0, prohíbe «vender» un producto o servicio cuyo valor derive sustancialmente de este software. Debe conservarse el texto completo de la licencia, incluidas estas menciones:",
        quote: "Software: Pearcleaner\nLicense: Apache 2.0 with Commons Clause\nLicensor: alienator88",
      },
    ],
  },
};

const t = computed(() => text[props.locale] ?? text["zh-Hans"]);
const sections = computed(() => [
  { key: "own", title: t.value.sections.own, items: groups.own },
  { key: "third", title: t.value.sections.third, items: groups.third },
  { key: "docs", title: t.value.sections.docs, items: groups.docs },
  { key: "assets", title: t.value.sections.assets, items: groups.assets },
]);
</script>

<template>
  <div class="licenses">
    <p class="lead">{{ t.lead }}</p>

    <section v-for="section in sections" :key="section.key" class="group">
      <h2 class="group-title">{{ section.title }}</h2>
      <ul class="rows">
        <li v-for="item in section.items" :key="item.key ?? item.name" class="row">
          <span class="name">{{ item.name }}</span>
          <span class="pill">{{ item.license }}</span>
          <span class="meta">{{ t.meta[item.key] }}</span>
          <a v-if="item.link" class="link" :href="item.link" target="_blank" rel="noopener noreferrer">
            {{ t.view }}<span class="arrow" aria-hidden="true">↗</span>
          </a>
          <span v-else class="meta spacer" />
        </li>
      </ul>
    </section>

    <aside v-for="notice in t.notices" :key="notice.title" class="notice">
      <h3 class="notice-title">{{ notice.title }}</h3>
      <p class="notice-body">{{ notice.body }}</p>
      <pre v-if="notice.quote" class="notice-quote">{{ notice.quote }}</pre>
    </aside>
  </div>
</template>

<style scoped>
.licenses {
  margin-top: 4px;
}

.lead {
  margin: 0 0 34px;
  font-size: 15px;
  line-height: 1.8;
  color: var(--vp-c-text-2);
}

.group {
  margin-top: 34px;
}

.group-title {
  display: flex;
  align-items: center;
  gap: 14px;
  margin: 0;
  border: none;
  padding: 0;
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--vp-c-text-3);
}

.group-title::after {
  content: "";
  flex: 1;
  height: 1px;
  background: var(--vp-c-divider);
}

.rows {
  margin: 10px 0 0;
  padding: 0;
  list-style: none;
}

.row {
  display: flex;
  align-items: baseline;
  gap: 14px;
  padding: 15px 14px;
  border-radius: 10px;
  transition: background-color 0.2s ease;
}

.row:hover {
  background: var(--vp-c-bg-soft);
}

.row + .row {
  box-shadow: inset 0 1px 0 var(--vp-c-divider);
}

.name {
  flex: 0 0 auto;
  min-width: 168px;
  font-size: 15px;
  font-weight: 600;
  color: var(--vp-c-text-1);
}

.pill {
  flex: 0 0 auto;
  padding: 2px 9px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 999px;
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  line-height: 18px;
  color: var(--vp-c-text-2);
  white-space: nowrap;
}

.meta {
  flex: 1 1 auto;
  font-size: 13px;
  line-height: 1.6;
  color: var(--vp-c-text-3);
}

.link {
  flex: 0 0 auto;
  font-size: 13px;
  font-weight: 500;
  color: var(--vp-c-brand-1);
  text-decoration: none;
  white-space: nowrap;
}

.link:hover {
  text-decoration: underline;
}

.arrow {
  margin-left: 3px;
  font-size: 12px;
}

.spacer:empty {
  display: none;
}

.notice {
  margin-top: 22px;
  padding: 16px 18px;
  border-left: 3px solid var(--vp-c-brand-1);
  border-radius: 12px;
  background: var(--vp-c-bg-soft);
}

.notice-title {
  margin: 0 0 8px;
  border: none;
  padding: 0;
  font-size: 13px;
  font-weight: 600;
  color: var(--vp-c-text-1);
}

.notice-body {
  margin: 0;
  font-size: 13px;
  line-height: 1.8;
  color: var(--vp-c-text-2);
}

.notice-quote {
  margin: 12px 0 0;
  padding: 10px 12px;
  border-radius: 8px;
  background: var(--vp-c-bg);
  font-family: var(--vp-font-family-mono);
  font-size: 12px;
  line-height: 1.7;
  color: var(--vp-c-text-2);
  white-space: pre-line;
  overflow-x: auto;
}

@media (max-width: 720px) {
  .row {
    flex-wrap: wrap;
    gap: 8px 12px;
  }

  .name {
    min-width: 0;
  }

  .meta {
    flex-basis: 100%;
  }
}
</style>
