<output data-js="now"><noscript>Offline</noscript></output>

<script type=module>
let el = document.querySelector('[data-js=now]')

if (new Date().getHours() < 8) {
  el.textContent = 'Asleep'
} else if (Math.random() < 0.01) {
  el.textContent = 'たぶん tooting'
} else if (Math.random() < 0.1) {
  el.textContent = 'Probably burping'
} else if (Math.random() < 0.001) {
  el.textContent = 'In a car?'
} else {
  el.textContent = 'Who knows'
}
</script>
