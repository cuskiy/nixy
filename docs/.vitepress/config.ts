import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Nixy',
  description: 'Lightweight NixOS/Darwin/Home Manager framework',

  head: [
    ['link', { rel: 'icon', href: '/logo.svg' }],
  ],

  locales: {
    root: {
      label: 'English',
      lang: 'en',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/getting-started' },
          { text: 'API', link: '/api' },
          { text: 'Examples', link: '/examples/minimal' },
        ],
        sidebar: [
          {
            text: 'Guide',
            items: [
              { text: 'Getting Started', link: '/getting-started' },
              { text: 'Configuration', link: '/configuration' },
              { text: 'Schema & Modules', link: '/schema-and-modules' },
              { text: 'Hosts', link: '/hosts' },
            ],
          },
          {
            text: 'Reference',
            items: [
              { text: 'Helpers', link: '/helpers' },
              { text: 'API', link: '/api' },
            ],
          },
          {
            text: 'Examples',
            items: [
              { text: 'Minimal', link: '/examples/minimal' },
              { text: 'Complex', link: '/examples/complex' },
            ],
          },
        ],
      },
    },
    zh: {
      label: '中文',
      lang: 'zh-CN',
      themeConfig: {
        nav: [
          { text: '指南', link: '/zh/getting-started' },
          { text: 'API', link: '/zh/api' },
          { text: '示例', link: '/zh/examples/minimal' },
        ],
        sidebar: [
          {
            text: '指南',
            items: [
              { text: '快速开始', link: '/zh/getting-started' },
              { text: '配置', link: '/zh/configuration' },
              { text: 'Schema 与 Modules', link: '/zh/schema-and-modules' },
              { text: 'Hosts', link: '/zh/hosts' },
            ],
          },
          {
            text: '参考',
            items: [
              { text: 'Helpers', link: '/zh/helpers' },
              { text: 'API', link: '/zh/api' },
            ],
          },
          {
            text: '示例',
            items: [
              { text: '最小配置', link: '/zh/examples/minimal' },
              { text: '复杂配置', link: '/zh/examples/complex' },
            ],
          },
        ],
      },
    },
  },

  themeConfig: {
    logo: '/logo.svg',
    socialLinks: [
      { icon: 'github', link: 'https://github.com/anialic/nixy' },
    ],
    search: {
      provider: 'local',
    },
    editLink: {
      pattern: 'https://github.com/anialic/nixy/edit/main/docs/:path',
    },
  },
})
