declare module 'live_vue' {
  import { Component, App } from 'vue';
  import { ViewHook } from 'phoenix_live_view';

  export interface SetupContext {
    createApp: typeof import('vue').createApp;
    component: Component;
    props: Record<string, unknown>;
    slots: Record<string, () => unknown>;
    plugin: import('vue').Plugin;
    el: Element;
    ssr: boolean;
  }

  export interface LiveVueOptions {
    resolve: (path: string) => Component | undefined | null;
    setup?: (context: SetupContext) => App;
  }

  export interface VueArgs {
    props: Record<string, any>;
    slots: Record<string, any>;
    app: App<Element>;
  }

  export interface LiveHook extends ViewHook {
    vue: VueArgs;
    liveSocket: any;
  }

  export const getHooks: (options: LiveVueOptions) => { VueHook: LiveHook };
  export const createLiveVue: (options: LiveVueOptions) => any;
  
  // Vite plugin
  export default function liveVuePlugin(): any;
} 