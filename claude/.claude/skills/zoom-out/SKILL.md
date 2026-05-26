---
name: zoom-out
description: Help the user build understanding when they're lost, confused, or overwhelmed by a topic, codebase, concept, or decision. Diagnose the kind of confusion first, pick the right zoom level (metaphor, glossary, mental model, history, or walk-through), anchor on what the user already knows, and build up in small steps — never dump more information on a confused person. Trigger on 'I'm lost', 'I don't understand', 'I'm confused', 'help me understand', 'explain this', 'step back', 'zoom out', 'big picture', 'give me context', 'what's going on here', 'I don't get it', 'this is overwhelming', or any signal that the user needs orientation more than execution.
---

# Zoom out — help the user re-orient

When the user is lost, the wrong response is *more information*. The right response is to figure out **what kind of lost they are**, meet them at that level, and rebuild understanding from solid ground upward.

## 1. Diagnose the confusion first — don't start explaining

Before saying anything substantive, identify which kind of "lost" the user is in. Ask **one short question** if it isn't obvious:

| Symptom in their message | Kind of lost | Where to start |
|---|---|---|
| Unknown jargon, words they can't define | **Vocabulary** | Glossary — define terms first |
| "I know what each piece does but not why they exist" | **Purpose** | Step up one level — what problem does this solve? |
| "I see the parts but not how they fit" | **Structure / relationships** | Build a small diagram or mental map |
| "I don't know how we got here" | **History** | Walk the timeline of decisions / commits / ADRs |
| "I'm seeing too much at once" | **Overload** | Reduce scope — pick one slice and go deep on just that |
| "I followed each step but can't reproduce it" | **Procedure** | Walk through one concrete example, slowly |
| "I get the abstract idea but not what to do" | **Application** | One concrete example tied to their actual code |

The diagnosis dictates the strategy. Skipping this step is the most common mistake.

## 2. Anchor on what they already know

Before adding new information, find their **existing ground**. Ask: *"What do you already understand about this?"* or *"What's the part that does make sense to you?"*

Two reasons:
- It tells you where to attach the new explanation, so it sticks.
- It restores the user's confidence — they discover they're not starting from zero.

If they say "nothing", probe: *"What's similar to this that you've worked with before?"* Almost everyone has analogous experience; surface it.

## 3. Pick the zoom level deliberately — go up, not sideways

When someone is confused at level N, **explaining harder at level N rarely helps**. Go up one level:

- Confused about a function? → Talk about the module it lives in and what it's for.
- Confused about a module? → Talk about the bounded context and the problem it solves.
- Confused about an architecture? → Talk about the business and the constraints that shaped it.
- Confused about a decision? → Read the ADR for the *why*, not the *what*.

Then come back down. The "up first" move is what zoom-out actually means.

## 4. Use analogies — but only one at a time, and call them out

A good analogy maps an unfamiliar structure onto a familiar one. Rules:

- **Use something they already know** (from §2). A generic "it's like a pipeline" helps no one if pipelines aren't familiar.
- **Be honest about where the analogy breaks down.** *"It's like a post office — you drop a letter and someone else picks it up. **Where it differs:** in our case the letter can be picked up by zero or many readers."*
- **Switch analogies if one isn't landing.** Don't double down.
- **Never stack three analogies in one explanation.** That's worse than no analogy.

## 5. Build up in small chunks — check in often

Confused users have a small working-memory budget. Burn it carefully.

- Give **one** idea, in **one** short paragraph.
- Then ask: *"Does that part make sense?"* or *"Where does this stop making sense?"*
- Wait for the answer before adding the next piece.
- If they say "yes" but don't elaborate, ask them to **explain it back in their own words**. That's the only honest test of understanding.

Never deliver a 5-paragraph essay to a confused person. They will skim, miss the key sentence, and feel worse.

## 6. Use the right artifact — words aren't always best

Match the medium to the kind of lost (§1):

- **Vocabulary** → a tiny inline table: *Term — what it means — what it is **not**.*
- **Structure** → ASCII diagram of the 3-5 boxes that matter, with arrows. Skip every other box.
- **History** → a 3-line timeline (Then we had X. Then Y happened. So we changed to Z).
- **Application** → a concrete worked example with real names from their code.
- **Mental model** → a one-sentence metaphor + the one place it breaks down (§4).

Don't reach for a 30-line diagram when 3 boxes suffice. The artifact should fit in one screen.

## 7. Re-zoom when the explanation isn't landing

If after two attempts the user still seems lost, **change the diagnosis, not the volume**:

- "Let me try a different angle — *forget what I just said.* What if I told you the whole point of this is X?"
- "We may be at the wrong level. Tell me — is the part that's hard the *vocabulary*, the *why*, or the *how to do it*?"

Repeating the same explanation louder is the failure mode to avoid.

## 8. Know when to stop — and when to switch back to doing

You're done when the user can:
- **Restate the concept in their own words** without using your phrasing.
- **Predict what would happen** in a variant case you didn't cover.
- Or simply tell you *"okay, I've got it — let's keep going."*

Then **switch back to action**. Don't keep elaborating after the lights come on — that's just dimming them again.

## 9. Anti-patterns — never do these

- **Don't repeat the jargon that caused the confusion.** Define it once, then use plain words.
- **Don't deliver an info-dump** ("here are the 12 things you need to know about X"). That's the opposite of zooming out.
- **Don't assume the level of confusion** ("you probably don't know what a Kafka topic is"). Ask.
- **Don't apologise for their confusion** ("sorry this is so complicated") — it implies they should already know. Confusion is information; treat it as a signal, not a flaw.
- **Don't switch tasks while they're still lost.** Resolve the confusion or explicitly park it ("let's note this and come back") — don't move on silently.
- **Don't lecture.** This is a dialogue. One paragraph, then their turn.
- **Don't fix the code while they're confused about the concept.** The fix won't stick. Resolve the understanding first, then act.

## 10. The shortest possible mental model

> **Diagnose → anchor → up one level → small chunk → check → repeat.**

That's the loop. Every step is short. Every step ends with the user's voice, not yours.
