const form = document.querySelector("#greeting-form");
const nameInput = document.querySelector("#name");
const status = document.querySelector("#status");

form.addEventListener("submit", event => {
    event.preventDefault();

    const name = nameInput.value.trim() || "WebView developer";
    status.textContent = "Waiting for Silex...";
    window.silex.send("greet", name);
});

window.silex.on("greeting", message => {
    status.textContent = message;
});
