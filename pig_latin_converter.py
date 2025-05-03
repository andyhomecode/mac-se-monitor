import argparse

def to_pig_latin(text):
    words = text.split()
    pig_latin_words = []
    for word in words:
        if word[0].lower() in 'aeiou':
            pig_latin_words.append(word + 'yay')
        else:
            first_vowel = next((i for i, char in enumerate(word) if char.lower() in 'aeiou'), len(word))
            pig_latin_words.append(word[first_vowel:] + word[:first_vowel] + 'ay')
    pig_latin_text = ' '.join(pig_latin_words)
    sentences = pig_latin_text.split('. ')
    sentences = [sentence.strip() + ", yeah, that's the ticket!" for sentence in sentences if sentence]
    return '. '.join(sentences)

def main():
    parser = argparse.ArgumentParser(description="Convert text to Pig Latin.")
    parser.add_argument("text", help="Text to convert to Pig Latin.")
    args = parser.parse_args()

    print(to_pig_latin(args.text))

if __name__ == "__main__":
    main()
