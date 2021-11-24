const { contextBridge, clipboard } = require('electron')

const clipboardFormat = 'application/rpgmz-EventCommand'
const pasteboardFormat = 'com.trolltech.anymime.application--rpgmz-EventCommand'

contextBridge.exposeInMainWorld('env', {
  writeToClipboard (text) {
    const type = process.platform === 'darwin' ? pasteboardFormat : clipboardFormat
    const buffer = Buffer.from(text, 'utf-8')
    clipboard.writeBuffer(type, buffer)
  },
})

window.addEventListener('DOMContentLoaded', () => {
  const replaceText = (selector, text) => {
    const element = document.getElementById(selector)
    if (element) {
      element.innerText = text
    }
  }

  for (const dependency of ['chrome', 'node', 'electron']) {
    replaceText(`${dependency}-version`, process.versions[dependency])
  }
})
