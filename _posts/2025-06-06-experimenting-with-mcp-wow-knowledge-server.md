---
layout: post
title: Experimenting with MCP - Building an Evergreen Knowledge Server for WoW Specs
categories: [AI, Gaming, MCP]
excerpt: Learn how to build a Model Context Protocol (MCP) server that provides real-time knowledge about various World of Warcraft specializations, connecting LLMs like Claude to current game information.
---

# Experimenting with MCP: Building an Evergreen Knowledge Server for WoW Specs

---

## Introduction: What is MCP?

The **Model Context Protocol (MCP)** is an open protocol that lets you build servers which provide context, tools, and resources to Large Language Models (LLMs) like Claude or ChatGPT. It enables connecting custom knowledge, workflows, and data to AI assistants in real-time.

### Key Benefits of MCP
- **Live Knowledge:** MCP lets you connect LLMs to real-time, up-to-date data and tools, not just static training data.
- **Composable:** You can add new tools, resources, or prompts for various domains including games, business, and research.
- **Separation of Concerns:** The LLM focuses on reasoning and synthesis, while your MCP server handles data fetching, business logic, or integration with external systems.
- **Open and Extensible:** Anyone can build and run their own MCP server, and any LLM client that supports MCP can use it.

This makes MCP perfect for things like:
- Game knowledge bots (like our WoW specializations server)
- Custom data dashboards
- Workflow automation
- Integrating LLMs with private or proprietary data

---

## The Project: An Evergreen WoW Specs Knowledge Server

### What We Built
- **A Node.js MCP server** using the [mcp-framework](https://github.com/QuantGeekDev/mcp-framework)
- **A custom tool** that fetches live, up-to-date information about various WoW specializations from top WoW sites (Murlok.io, Wowhead, Icy Veins, Method)
- **Integration with Claude Desktop** so the LLM can call the tool and synthesize answers for any WoW spec question

### How It Works
1. **User asks a question** (e.g., "What are the best stats for Vengeance Demon Hunter in Mythic+?")
2. **The MCP tool matches the question** to relevant topics and URLs using a pre-built resource index
3. **It fetches and parses live data** from the best sources (ensuring up-to-date information)
4. **Returns the extracted info** (with source links) to the LLM, which combines and presents the answer

---

## Example: Stat Weights from Murlok.io

**User Input:**
```
What are the stat weights for Vengeance Demon Hunter in Mythic+?
```

**MCP Tool Output:**
```json
{
  "question": "What are the stat weights for Vengeance Demon Hunter in Mythic+?",
  "sources": [
    {
      "url": "https://murlok.io/demon-hunter/vengeance/mm+",
      "content": "Secondary Stats\nHaste - 32% (2129 rating)\nCritical Strike - 33% (1591 rating)\nVersatility - 7% (558 rating)\nMastery - 29% (453 rating)\nMinor Stats\nLeech - 13% (328 rating)\nAvoidance - 1% (415 rating)\nSpeed - 2% (0 rating)"
    }
  ]
}
```

**LLM Synthesized Answer:**
> The current stat priority for Vengeance Demon Hunter in Mythic+ (from Murlok.io, top 50 players, Patch 11.1) is:
> - Haste: 32%
> - Critical Strike: 33%
> - Versatility: 7%
> - Mastery: 29%
> - Leech: 13% (minor stat)
> - Avoidance: 1% (minor stat)
> - Speed: 2% (minor stat)
>
> Data is refreshed every 8 hours and reflects what top players are actually using.

---

## More Example Inputs and Outputs

### Example 2: Talents for Raiding

**User Input:**
```
What are the best talents for Vengeance Demon Hunter in raids?
```

**MCP Tool Output:**
```json
{
  "question": "What are the best talents for Vengeance Demon Hunter in raids?",
  "sources": [
    {
      "url": "https://www.method.gg/guides/vengeance-demon-hunter/talents",
      "content": "Talent Builds\nFel-Scarred - Single Target/Cleave\nAldrachi - Single Target\nFel Scarred Cleave\nAldrachi Reaver - Cleave\nAldrachi Reaver - Mythic+\nFel-Scarred - Mythic+\nClass Talents\nSpec Talents\nHero Talents\nAldrachi Reaver\nFel-Scarred"
    }
  ]
}
```

**LLM Synthesized Answer:**
> For raiding as a Vengeance Demon Hunter, top talent builds include Fel-Scarred for single target/cleave and Aldrachi Reaver for single target. See Method.gg for full builds and explanations.

---

### Example 3: Consumables and Enchants

**User Input:**
```
What consumables and enchants should I use as a Vengeance Demon Hunter tank?
```

**MCP Tool Output:**
```json
{
  "question": "What consumables and enchants should I use as a Vengeance Demon Hunter tank?",
  "sources": [
    {
      "url": "https://www.icy-veins.com/wow/vengeance-demon-hunter-pve-tank-gems-enchants-consumables",
      "content": "Best Enchants for Vengeance Demon Hunter\nBest Gems for Vengeance Demon Hunter in The War Within\nBest Flask for Vengeance Demon Hunter in The War Within\nBest Weapon Oil/Stone for Vengeance Demon Hunter in The War Within\nBest Potion for Vengeance Demon Hunter in The War Within\nBest Food for Vengeance Demon Hunter in The War Within"
    }
  ]
}
```

**LLM Synthesized Answer:**
> For consumables and enchants, use the best gems, flasks, weapon oils, potions, and food as recommended by Icy Veins for the current patch. Always check for the latest updates!

---

## How We Built It

1. **Compiled a list of trusted URLs** for VDH guides and stats
2. **Wrote a Node.js tool** that:
    - Loads a resource index (with topics/headings scraped from each site)
    - Matches user questions to relevant topics/URLs
    - Fetches and parses the live HTML using `axios` and `cheerio`
    - Extracts the most relevant section for the question
    - Returns the info and source links to the LLM
3. **Integrated with Claude Desktop** by adding this to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "wow-vdh": {
      "command": "node",
      "args": ["C:/Users/bashby/projects/mcp/wow-mcp/dist/index.js"]
    }
  }
}
```

---

## Key Advantages
- **Always up-to-date:** Retrieves current data directly from authoritative sources
- **Multi-source:** Combines info from Wowhead, Icy Veins, Method, Murlok.io, and more
- **Single point of access:** Users can ask a single question to a single source (the AI) which scrapes answers from various sources and combines them to create the best comprehensive answer
- **LLM-ready:** Returns structured, source-linked data for the LLM to synthesize
- **Composable:** You can add additional tools, resources, or prompts for various games, topics, or workflows

---

## Key Takeaways
- MCP effectively extends LLMs with custom, real-time knowledge sources
- Node.js with appropriate libraries provides an efficient framework for fetching and parsing web data
- The architecture leverages LLMs for synthesis while focusing development efforts on providing quality data

---

## Want to Try It?
- Check out [mcp-framework](https://github.com/QuantGeekDev/mcp-framework)
- Fork this repo and add your own tools/resources
- Connect to Claude Desktop or any LLM client that supports MCP

---

*For more information on MCP, visit the resources linked above.*
