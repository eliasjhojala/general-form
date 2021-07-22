turbolinksSupported = () => {
  try {
    return Turbolinks.supported;
  } catch(_) {
    return false;
  }
}
