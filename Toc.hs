{-# OPTIONS_GHC -fno-warn-tabs #-}
{-# LANGUAGE RecordWildCards, OverloadedStrings, ViewPatterns #-}

module Toc (writeTocFile) where

import qualified Data.Text as Text
import Data.Time.Format (formatTime, defaultTimeLocale)
import Data.Time.Clock (getCurrentTime)
import Prelude hiding ((.), (++), writeFile)
import Render (
	render, secnum, Link(..), linkToSection, simpleRender, squareAbbr,
	fileContent, applySectionFileStyle, url, SectionFileStyle(..), outputDir)
import Util
import Load14882 (Figure(..), Table(..), Section(..), Draft(..), indexCatName, figures, tables)

tocSection :: Section -> Text
tocSection s@Section{..} =
	xml "div" [("id", simpleRender abbreviation)] $
	h (min 4 $ 2 + length parents) (
		secnum "" s ++ " " ++
		simpleRender (sectionName ++ " ", (linkToSection TocToSection abbreviation){aClass="abbr_ref"})) ++
	mconcat (tocSection . subsections)

tocChapter :: Section -> Text
tocChapter s@Section{..} =
	xml "div" [("id", simpleRender abbreviation)] $
	h (min 4 $ 2 + length parents) (
		secnum "" s ++ " " ++
		simpleRender (sectionName ++ " ", anchor{
			aClass = "folded_abbr_ref",
			aText  = "[" ++ simpleRender abbreviation ++ "]",
			aHref  = "#" ++ simpleRender abbreviation}) ++
		simpleRender (linkToSection TocToSection abbreviation){aClass="unfolded_abbr_ref"}) ++
	xml "div" [("class", "tocChapter")] (mconcat (tocSection . subsections))

listOfTables :: [Table] -> Text
listOfTables tables =
	xml "div" [("id", "tab")] $
		h 2 ("List of Tables "
			++ simpleRender abbrAnchor{aHref="#tab", aClass="folded_abbr_ref"}
			++ simpleRender abbrAnchor{aHref="TocToSection/tab", aClass="unfolded_abbr_ref"})
		++ xml "div" [("class", "tocChapter")] (mconcat (tableItem . tables))
	where
		abbrAnchor = anchor{aText="[tab]"}
		tableItem :: Table -> Text
		tableItem Table{..} =
			spanTag "secnum" (simpleRender tableNumber)
			++ simpleRender tableCaption
			++ simpleRender anchor{
				aHref  = "TocToSection/" ++ url (abbreviation tableSection)
				         ++ "#" ++ url (head tableAbbrs),
				aText  = squareAbbr (head tableAbbrs),
				aClass = "abbr_ref"}
			++ "<br>"

listOfFigures :: [Figure] -> Text
listOfFigures figures =
	xml "div" [("id", "fig")] $
		h 2 ("List of Figures "
			++ simpleRender abbrAnchor{aHref="#fig", aClass="folded_abbr_ref"}
			++ simpleRender abbrAnchor{aHref="TocToSection/fig", aClass="unfolded_abbr_ref"})
		++ xml "div" [("class", "tocChapter")] (mconcat (figureItem . figures))
	where
		abbrAnchor = anchor{aText="[fig]"}
		figureItem :: Figure -> Text
		figureItem Figure{..} =
			spanTag "secnum" (simpleRender figureNumber)
			++ simpleRender figureName
			++ simpleRender anchor{
				aHref  = "TocToSection/" ++ url (abbreviation figureSection)
				         ++ "#" ++ url figureAbbr,
				aText  = squareAbbr figureAbbr,
				aClass = "abbr_ref"}
			++ "<br>"

writeTocFile :: SectionFileStyle -> Draft -> IO ()
writeTocFile sfs draft@Draft{..} = do
	putStrLn "  toc"
	date <- Text.pack . formatTime defaultTimeLocale "%F" . getCurrentTime
	writeFile (outputDir ++ "/index.html") $ applySectionFileStyle sfs $
		fileContent "" "14882: Contents" $
			xml "div" [("class", "tocHeader")]
				( "Generated on " ++ date
				++ " from the C++ standard's <a href='" ++ commitUrl ++ "'>draft LaTeX sources</a>"
				++ " by <a href='https://github.com/Eelis/cxxdraft-htmlgen'>cxxdraft-htmlgen</a>."
				++ "<hr/>") ++
			"<h1>Contents</h1>" ++
			listOfTables (tables draft) ++
			listOfFigures (figures draft) ++
			mconcat (tocChapter . chapters) ++
			mconcat (h 2
				. (\cat -> simpleRender anchor{aHref="TocToSection/" ++ cat, aText=indexCatName cat})
				. ["generalindex", "libraryindex", "impldefindex"])
