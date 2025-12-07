import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.orthotrack.edgenode',
  appName: 'OrthoTrack Edge Node',
  webDir: 'dist',
  server: {
    // Para desenvolvimento localhost
    // Emulador: use androidHost para acessar localhost da máquina
    androidScheme: 'https',
    // Para desenvolvimento, você pode usar:
    // url: 'http://localhost:3001',
    // cleartext: true
  },
  android: {
    allowMixedContent: true,
    buildOptions: {
      keystorePath: undefined,
      keystoreAlias: undefined,
    },
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      launchAutoHide: true,
      backgroundColor: '#667eea',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
    },
    StatusBar: {
      style: 'light',
      backgroundColor: '#667eea',
    },
  },
};

export default config;






