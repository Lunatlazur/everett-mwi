<script setup lang="ts">
import { ref, computed } from 'vue'
import * as peggy from 'peggy'
import mwi from '../grammar/mwi.pegjs?raw'

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

const source = ref(`@if switch #1 on
@end

@if switch #2 off
@end

@if variable #2 == 1
@end

@if variable #2 == #3
@end

@if variable #3 > 1
@end

@if variable #3 >= 1
@end

@if variable #3 < 1
@end

@if variable #3 <= 1
@end

@if variable #3 != -1
@end

@if selfSwitch A on
@end

@if selfSwitch B off
@end

@if timer <= 60
@end

@if actor #1 inParty
@end

@if actor #1 name ハロルド
@end

@if actor #1 job #1
@end

@if actor #1 skill #1
@end

@if actor #1 weapon #1
@end

@if actor #1 armor #1
@end

@if actor #1 state #1
@end

@if enemy #1 appeared
@end

@if enemy #1 state #1
@end

@if money >= 100
@end

@if money <= 100
@end

@if money < 10
@end

@if item #1 inInventory
@end

@if weapon #1 inInventory includingEquip
@end

@if armor #1 inInventory includingEquip
@end

@if direction player up
@end

@if direction this left
@end

@if direction event #1 down
@end

@if button ok pressed
@end

@if button cancel triggered
@end

@if button down repeated
@end

@if vehicle boat
@end

@if vehicle ship
@end

@if vehicle airship
@end
`)

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
  const type = 'text/plain'
  try {
    const data = [
      new ClipboardItem({
        [type]: new Blob([value], { type }),
      }),
    ]
    await navigator.clipboard.write(data)
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
