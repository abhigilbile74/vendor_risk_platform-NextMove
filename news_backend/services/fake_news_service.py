TRUSTED_SOURCES = ["reuters", "bloomberg", "economic times", "cnbc"]

def is_trusted(source):
    return any(s in source.lower() for s in TRUSTED_SOURCES)

def detect_fake(text):
    fake_words = ["rumor", "fake", "unconfirmed", "leak"]
    return any(word in text.lower() for word in fake_words)

def authenticity(text, source):
    if not is_trusted(source):
        return "UNVERIFIED"
    if detect_fake(text):
        return "POSSIBLY FAKE"
    return "LIKELY TRUE"