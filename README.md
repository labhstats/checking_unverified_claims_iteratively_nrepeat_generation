# checking_unverified_claims_iteratively_nrepeat_generation
Open source reference "verification" tool using R, API (Ollama as is) and open weight LLMs. More automatically verify claims to the best of LLMs capability, given available text to verify and corresponding pdf of references. Prototyped and built using ChatGPT (https://chatgpt.com/).

**Warning**: LLMs are stochastic.

My experience is that this works well enough to more quickly verify textual claims yourself. Your experience may vary.

## Requires:
- R (used 4.4.2)
- RStudio (https://posit.co/download/rstudio-desktop/) 
- R package: tidyllm (https://cran.r-project.org/web/packages/tidyllm/index.html)
- Ollama (https://ollama.com/) or other API to LLM server

## Tested with:
- RTX 5070 12GB GPU (4-6s runtime per claim and source)
- 32GB RAM
- Ryzen 3700X CPU
- W11
- cogito:8b (https://ollama.com/library/cogito:8b)
- The following paper: https://bmjleader.bmj.com/content/7/1/3 (due to last read and being both interesting and open source; right before making this program)

## Inspiration and motivation:
True story https://www.nrk.no/tromsogfinnmark/tromso-kommune-har-henvist-til-litteratur-som-ikke-finnes-i-omstruktureringen-av-skoler-1.17358938

Wanting to have a FREE OPEN SOURCE tool which is able to run on modest and even dated consumer hardware with acceptable performance.

## Possible areas of Improvement:
- Verify multiple sources (sequentially) per claim. Should work already if nothing was coded wrong.
- Tokenize or chunk the input source to get page number.
- Tokenize or chunk the input sources to use all sources at the same time instead of one source per claim.
- Program to deconstruct pdf or text into a nested list structure used for iteratively checking unverified claims with corresponding sources at the end of the sentence. Specifically often the way writing happens in academic works or work based on scientific papers.
