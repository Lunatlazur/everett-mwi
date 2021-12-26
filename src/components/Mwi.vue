<script setup lang="ts">
import { ref, computed } from 'vue'
import * as peggy from 'peggy'
import mwi from '../grammar/mwi.pegjs?raw'
import grammer from '../grammar/grammar.mwi?raw'

type ParserError = peggy.GrammarError | peggy.parser.SyntaxError

function isParserError (e: any) : e is ParserError {
  return typeof e.format === 'function'
}

const parser = computed(() => {
  try {
    return peggy.generate(mwi, { grammarSource: 'mwi' })
  } catch (e) {
    if (isParserError(e)) {
      return e.format([{ source: 'mwi', text: mwi }])
    } else {
      console.error(e)
      return e as Error
    }
  }
})

const source = ref(grammer)

const result = computed(() => {
  if (typeof parser.value === 'string') {
    return {
      parsed: null,
      error: parser.value,
    }
  }
  if (parser.value instanceof Error) {
    return {
      parsed: null,
      error: parser.value,
    }
  }
  try {
    return {
      error: null,
      parsed: JSON.stringify(parser.value.parse(source.value, {
        grammarSource: 'input',
      }), null, '  '),
    }
  } catch (e) {
    if (isParserError(e)) {
      return {
        parsed: null,
        error: e.format([{ source: 'input', text: source.value }]),
      }
    } else {
      console.error(e)
      return {
        parsed: null,
        error: e as Error,
      }
    }
  }
})

async function copy () {
  const value = result.value.parsed
  if (typeof value !== 'string') {
    return
  }
  try {
    window.env.writeToClipboard(value)
  } catch (e) {
    console.error(e)
  }
}

</script>

<template>
  <div class="container">
    <div class="editor">
      <textarea v-model="source"></textarea>
    </div>
    <div class="result">
      <template v-if="result.parsed">
        <button @click="copy">コピー</button>
        <pre>{{ result.parsed }}</pre>
      </template>
      <template v-else>
        <pre>{{ result.error }}</pre>
      </template>
    </div>
  </div>
</template>

<style scoped>
.container {
  width: 100%;
  height: 100%;
  display: flex;
}
.container .editor {
  width: 50%;
  height: 100%;
}
.container .editor textarea {
  resize: none;
  box-sizing: border-box;
  height: 100%;
  max-height: 100%;
  width: 100%;
  max-width: 100%;
  padding: 1rem;
  overflow: scroll;
  outline: none;
  border: 0px;
  font-size: 100%;
  font-family: 'Fira Code', '源ノ角ゴシック', monospace;
}
.container .result {
  max-height: 100%;
  box-sizing: border-box;
  width: 50%;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
}
.container .result pre {
  flex-shrink: 1;
  overflow: scroll;
  height: 100%;
  max-height: 100%;
  font-size: 100%;
  margin: 0;
  padding: 1rem;
  line-height: 1.25;
  white-space: pre-wrap;
  font-family: 'Fira Code', '源ノ角ゴシック', monospace;
}
.container .result button {
  flex-shrink: 0;
  font-size: 100%;
  font-family: 'Fira Code', '源ノ角ゴシック', monospace;
  line-height: 2.0;
}
</style>
