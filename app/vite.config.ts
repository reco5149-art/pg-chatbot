import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import { writeFile } from 'node:fs/promises'

// 개발 서버 전용: /embed.html이 만든 자료 벡터를 public/pg-docs.json에 저장한다.
// 스키마(id, text, url, section, vector)와 768차원을 검사하고, 맞지 않으면 저장하지 않는다.
function saveDocs(): Plugin {
  return {
    name: 'pg-save-docs',
    apply: 'serve',
    configureServer(server) {
      server.middlewares.use('/__save-docs', (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405
          res.end('POST만 받습니다')
          return
        }
        let body = ''
        req.on('data', (c) => (body += c))
        req.on('end', async () => {
          try {
            const docs = JSON.parse(body)
            if (!Array.isArray(docs) || docs.length === 0) throw new Error('빈 배열입니다')
            const ids = new Set<string>()
            for (const d of docs) {
              const keys = Object.keys(d).sort().join(',')
              if (keys !== 'id,section,text,url,vector') throw new Error(`${d.id}: 필드가 id, text, url, section, vector가 아닙니다 (${keys})`)
              if (!/^PG-\d{3}$/.test(d.id)) throw new Error(`${d.id}: id 형식이 PG-001이 아닙니다`)
              if (ids.has(d.id)) throw new Error(`${d.id}: id가 중복됩니다`)
              ids.add(d.id)
              if (!Array.isArray(d.vector) || d.vector.length !== 768) throw new Error(`${d.id}: 벡터가 768차원이 아닙니다`)
            }
            await writeFile('public/pg-docs.json', JSON.stringify(docs) + '\n', 'utf8')
            res.end(`저장: public/pg-docs.json — ${docs.length}청크 × 768차원`)
          } catch (e) {
            res.statusCode = 400
            res.end(`저장하지 않았습니다: ${e instanceof Error ? e.message : String(e)}`)
          }
        })
      })
    },
  }
}

export default defineConfig({
  plugins: [react(), saveDocs()],
  base: './',
})
