LaTeX = {}
require('latex_unicode_mapping.coffee')

LaTeX.html = {
  sup: {prefix: '\\textsuperscript{', postfix: '}'}
  sub: {prefix: '\\textsubscript{', postfix: '}'}
  i: {prefix: '\\emph{', postfix: '}'}
  b: {prefix: '\\textbf{', postfix: '}'}
  span: {prefix: '', postfix: ''}
  smallcaps: {prefix: '\\textsc{', postfix: '}'}
}

LaTeX.re = {
  pre: /^<pre>(.*?)<\/pre>?(.*)/i
  br: /^<\/?(br|break|p)(\s[^>]*)?\/?>(.*)/i
  open: /^<(sup|sub|i|b|span)(\s[^>]*)?>(.*)/i
  close: /^<\/(sup|sub|i|b|span)(\s[^>]*)?>(.*)/i
}

LaTeX.emit = ->
  if @acc.text != ''
    if @acc.math
      if @acc.text.match(/^{[^{}]*}$/)
        @latex += "\\ensuremath#{@acc.text}"
      else
        @latex += "\\ensuremath{#{@acc.text}}"
    else
      @latex += @acc.text
  @acc = { math: false, text: ''}
  return

require('BraceBalancer.js')

LaTeX.html2latex = (text) ->
  stack = []
  mapping = (if Translator.unicode then @toLaTeX.unicode else @toLaTeX.ascii)

  @latex = ''
  @acc = { math: false, text: ''}

  while text.length > 0
    switch
      when m = text.match(@re.pre)
        @emit()

        @latex += m[1]
        text = m[2]

      when m = text.match(@re.br)
        @emit()

        @latex += "\n\n"
        text = m[3]

      when m = text.match(@re.open)
        @emit()

        tag = m[1].toLowerCase()
        repl = (if tag == 'span' && m[2]?.toLowerCase().match(/small-caps/) then 'smallcaps' else tag)
        stack.unshift({tag: tag, postfix: @html[repl].postfix})
        @latex += @html[repl].prefix
        text = m[3]

      when m = text.match(@re.close)
        @emit()

        tag = m[1].toLowerCase()

        while stack.length > 0
          @latex += stack[0].postfix
          break if stack.shift().tag == tag

        text = m[3]

      when mapping.math[text[0]]
        @emit() unless @acc.math
        @acc.math = true
        @acc.text += mapping.math[text[0]]
        text = text.substring(1)

      else
        @emit() if @acc.math
        @acc.math = false
        @acc.text += mapping.text[text[0]] || text[0]
        text = text.substring(1)

  @emit()

  for tag in stack
    @latex += tag.postfix

  return BetterBibTeXBraceBalancer.parse(@latex) if @latex.indexOf("\\{") >= 0 || @latex.indexOf("\\textleftbrace") || @latex.indexOf("\\}") >= 0 || @latex.indexOf("\\textrightbrace")
  return @latex
