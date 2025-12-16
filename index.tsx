import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

// [중요] 브라우저(Vite) 환경에서 process.env를 사용하기 위한 설정
// 이 코드가 없으면 앱이 "process is not defined" 오류로 멈춥니다(빈 화면 원인).
try {
  if (typeof process === 'undefined') {
    (window as any).process = { env: {} };
  }
  // Vercel/Vite 환경 변수(import.meta.env)를 process.env로 연결
  // @ts-ignore
  if (typeof import.meta !== 'undefined' && import.meta.env) {
    // @ts-ignore
    (window as any).process.env.API_KEY = import.meta.env.VITE_API_KEY;
  }
} catch (e) {
  console.warn("Env polyfill warning:", e);
}

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error("Could not find root element to mount to");
}

const root = ReactDOM.createRoot(rootElement);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);