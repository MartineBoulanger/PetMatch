PetMatch.PetJournal = {}

function PetMatch.PetJournal:Initialize()
  if not PetJournalFrame then
    return
  end
  addon.Logger:Info(
    "Pet Journal detected"
  )
end
