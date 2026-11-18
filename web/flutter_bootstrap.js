{{flutter_js}}
{{flutter_build_config}}

const loadingMessage = document.getElementById(
  "app-loading-message",
);

function updateLoadingMessage(message) {
  if (loadingMessage !== null) {
    loadingMessage.textContent = message;
  }
}

function removeLoadingScreen() {
  const loadingScreen = document.getElementById(
    "app-loading",
  );

  if (loadingScreen === null) {
    return;
  }

  loadingScreen.style.opacity = "0";
  loadingScreen.style.transition =
      "opacity 180ms ease-out";

  window.setTimeout(() => {
    loadingScreen.remove();
  }, 180);
}

function showLoadingError(error) {
  const spinner = document.getElementById(
    "app-loading-spinner",
  );

  if (spinner !== null) {
    spinner.style.display = "none";
  }

  updateLoadingMessage(
    "Die Anwendung konnte nicht geladen werden. Bitte lade die Seite neu.",
  );

  console.error(
    "Flutter konnte nicht gestartet werden:",
    error,
  );
}

_flutter.loader.load({
  onEntrypointLoaded: async function (
    engineInitializer,
  ) {
    try {
      updateLoadingMessage(
        "Anwendung wird vorbereitet …",
      );

      const appRunner =
          await engineInitializer.initializeEngine();

      updateLoadingMessage(
        "Stadtschreiber wird gestartet …",
      );

      await appRunner.runApp();

      removeLoadingScreen();
    } catch (error) {
      showLoadingError(error);
    }
  },
});