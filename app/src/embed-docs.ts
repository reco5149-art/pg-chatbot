// 개발용: 자료 청크 → 768차원 벡터 → public/pg-docs.json
// 챗봇의 질문 임베딩과 같은 함수(rag.ts의 embed)를 써서 문서·질문이 같은 벡터 공간에 놓이게 한다.
import { embed, onEmbedProgress, retrieve } from "./rag";

interface SourceChunk {
  id: string;
  text: string;
  url: string;
  section: string;
}

const logEl = document.getElementById("log")!;
const btn = document.getElementById("run") as HTMLButtonElement;
const lines: string[] = [];
const log = (s: string) => {
  lines.push(s);
  logEl.textContent = lines.join("\n");
};

// 저장 직후 검색이 제대로 되는지 보는 확인 질문 (README 실험의 고정 질문 일부)
const CHECK_QUESTIONS = ["체험 수업 비용이 얼마예요?", "토요일에도 운동할 수 있어요?", "내일 날씨 어때?"];

onEmbedProgress((p) => {
  if (p.cached) return;
  if (p.pct % 10 === 0) log(`  모델 내려받는 중 ${p.file} ${p.pct}%`);
});

btn.addEventListener("click", async () => {
  btn.disabled = true;
  lines.length = 0;
  try {
    const res = await fetch("/data/pg-chunks.json", { cache: "no-store" });
    if (!res.ok) throw new Error(`data/pg-chunks.json을 읽지 못했습니다 (${res.status})`);
    const chunks = (await res.json()) as SourceChunk[];
    log(`청크 ${chunks.length}개를 읽었습니다. 첫 실행은 임베딩 모델(약 200MB)을 내려받습니다.`);

    const out = [];
    for (const c of chunks) {
      const vector = await embed(c.text);
      const norm = Math.sqrt(vector.reduce((s, x) => s + x * x, 0));
      out.push({ id: c.id, text: c.text, url: c.url, section: c.section, vector });
      log(`✓ ${c.id} (${c.section}) — ${vector.length}차원, 노름 ${norm.toFixed(4)}`);
    }

    const save = await fetch("/__save-docs", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(out),
    });
    const msg = await save.text();
    if (!save.ok) throw new Error(msg);
    log(`\n${msg}`);

    log("\n확인 검색 (상위 3개):");
    // 개발 서버가 새 파일을 알아차리기까지 잠깐 걸릴 수 있어 몇 번 다시 시도한다
    const retrieveRetry = async (q: string) => {
      for (let i = 0; ; i++) {
        try {
          return await retrieve(q, 15);
        } catch (e) {
          if (i >= 6) throw e;
          await new Promise((r) => setTimeout(r, 500));
        }
      }
    };
    for (const q of CHECK_QUESTIONS) {
      const hits = await retrieveRetry(q);
      const top = hits.slice(0, 3).map((h) => `${h.chunk.id} ${(h.score * 100).toFixed(1)}%`).join(" · ");
      log(`  Q: ${q}${hits[0].score < 0.55 ? "  ⚠ 약한 근거" : ""}\n     ${top}`);
    }
    log("\n완료. 챗봇 화면(/)을 새로고침하면 새 자료로 답합니다.");
    logEl.className = "ok";
  } catch (e) {
    log(`\n오류: ${e instanceof Error ? e.message : String(e)}`);
    logEl.className = "bad";
  } finally {
    btn.disabled = false;
  }
});
