{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2011-2022, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Objects, records etc that encapsulate a code snippet, its data and lists of
 * code snippets.
}


unit DB.USnippet;


interface


uses
  // Delphi
  Classes,
  Generics.Collections,
  Generics.Defaults,
  // Project
  ActiveText.UMain,
  Compilers.UGlobals,
  DB.USnippetKind,
  DB.Vaults,
  UContainers,
  UIStringList,
  USnippetIDs;

type
  ///  <summary>Enumeration providing information about the level to which a
  ///  snippet has been tested.</summary>
  TSnippetTestInfo = (
    stiNone,              // snippet has not been tested
    stiBasic,             // snippet has had some basic testing
    stiAdvanced,          // snippet has had unspecified advanced testing
    stiUnitTests,         // snippet has unit tests
    stiDemoCode           // snippet has a demo program
  );

type

  {
  TSnippetData:
    Record that provides information about a snippet's properties.
  }
  TSnippetData = record
    Kind: TSnippetKind;                   // Kind of snippet
    Cat: string;                          // Category containing snippet
    Desc: IActiveText;                    // Description of snippet
    SourceCode: string;                   // Snippet's source code
    HiliteSource: Boolean;                // If syntax highlighter to be used
    DisplayName: string;                  // Snippet's display name
    Extra: IActiveText;                   // Extra text used to describe snippet
    CompilerResults: TCompileResults;     // Compilation results
    TestInfo: TSnippetTestInfo;           // Test information
    procedure Init;
      {Initialises record by setting default values for fields.
      }
    procedure Assign(const Src: TSnippetData);
      {Sets this record to be a copy of another record.
        @param Src [in] Record to be copied.
      }
  end;

  {
  TSnippetReferences:
    Record that details a snippet's references
  }
  TSnippetReferences = record
    Units: IStringList;         // List of required units
    Depends: ISnippetIDList;    // List of IDs of required snippets
    XRef: ISnippetIDList;       // List of IDs of cross referenced snippets
    procedure Init;
      {Initialises record by creating objects stored in fields.
      }
    procedure Assign(const Src: TSnippetReferences);
      {Sets this record to be a copy of another record.
        @param Src [in] Record to be copied.
      }
  end;

  {
  TSnippetEditData:
    Provides deatils of a snippet's data that can be edited.
  }
  TSnippetEditData = record
    Props: TSnippetData;        // Snippet's editable properties
    Refs: TSnippetReferences;   // Snippet's editable referfences
    procedure Init;
      {Initialises record by creating default values and field objects.
      }
    procedure Assign(const Src: TSnippetEditData);
      {Sets this record to be a copy of another record.
        @param Src [in] Record to be copied.
      }
  end;

  TSnippetList = class;

  {
  TSnippet:
    Encapsulates a snippet from the database. Can be routine, type, constant or
    free-form.
  }
  TSnippet = class(TObject)
  public
    ///  <summary>Comparer for snippets by display name.</summary>
    type
      TComparer = class(TInterfacedObject,
        IComparer<TSnippet>, IEqualityComparer<TSnippet>
      )
      public
        function Compare(const Left, Right: TSnippet): Integer;
        function Equals(const Left, Right: TSnippet): Boolean;
          reintroduce;
        function GetHashCode(const Value: TSnippet): Integer;
          reintroduce;
      end;
      TDisplayNameComparer = class(TComparer<TSnippet>)
      public
        ///  <summary>Compares snippets Left and Right. Returns -ve if Left's
        ///  display name sorts before Right's, 0 if the same or +ve if Left's
        ///  display name is greater than Right's.</summary>
        function Compare(const Left, Right: TSnippet): Integer; override;
      end;
  strict private
    fKind: TSnippetKind;                    // Kind of snippet this is
    fCategory: string;                      // Name of snippet's category
    fDescription: IActiveText;              // Description of snippet
    fSourceCode: string;                    // Snippet source code
    fKey: string;                           // Snippet key: unique in collection
    fDisplayName: string;                   // Display name of snippet
    fUnits: TStringList;                    // List of required units
    fDepends: TSnippetList;                 // List of required snippets
    fXRef: TSnippetList;                    // List of cross-referenced snippets
    fExtra: IActiveText;                    // Further information for snippet
    fCompatibility: TCompileResults;        // Snippet's compiler compatibility
    fCollectionID: TVaultID;                // Snippet's vault ID
    fHiliteSource: Boolean;                 // If source is syntax highlighted
    fTestInfo: TSnippetTestInfo;            // Level of testing of snippet
    function GetID: TSnippetID;
      {Gets snippet's unique ID.
        @return Required ID.
      }
    function GetDisplayName: string;
      {Gets snippet's display name, or name if no display name is set
        @return Required display name.
      }
  strict protected
    procedure SetKey(const AKey: string);
      {Sets Key property.
        @param AKey [in] New key.
      }
    procedure SetProps(const Data: TSnippetData);
      {Sets snippet's properties.
        @param Data [in] Record containing property values.
      }
    function GetDisplayNameValue: string;
      {Get's value of snippet's display name field.
        @return Required field content.
      }
  public

    ///  <summary>Object constructor. Sets up snippet object with given property
    ///  values belonging to a specified collection.</summary>
    ///  <param name="AKey"><c>string</c> [in] Snippet's key.</param>
    ///  <param name="ACollectionID"><c>TVaultID</c> [in] ID of vault to which
    ///  the snippet belongs. ID must not be null.</param>
    ///  <param name="Props"><c>TSnippetData</c> [in] Values of snippet
    ///  properties.</param>
    constructor Create(const AKey: string; const ACollectionID: TVaultID;
      const Props: TSnippetData);

    destructor Destroy; override;
      {Destructor. Tears down object.
      }
    ///  <summary>Compares this snippet with another.</summary>
    ///  <param name="Snippet"><c>TSnippet</c> [in] Snippet to compare with.
    ///  </param>
    ///  <returns><c>Integer</c>. <c>0</c> if the snippets are the same, -ve if
    ///  this snippet is less than <c>Snippets</c> or +ve if this snippet is
    ///  greater than <c>Snippet</c>.</returns>
    function CompareTo(const Snippet: TSnippet): Integer;
    function IsEqual(const Snippet: TSnippet): Boolean;
      {Checks if this snippet is same as another snippet. Snippets are
      considered equal if they have the same key and come from the same
      collection.
        @param Snippet [in] Snippet being compared.
        @return True if snippets are equal, False if not.
      }
    function CanCompile: Boolean;
      {Checks if snippet can be compiled.
        @return True if compilation supported and False if not.
      }
    ///  <summary>Returns the snippets hash code.</summary>
    function Hash: Integer;
    property Kind: TSnippetKind read fKind;
      {Kind of snippet represented by this object}
    property ID: TSnippetID read GetID;
      {Snippet's unique ID}
    property Key: string read fKey;
      {Snippet key}
    property DisplayName: string read GetDisplayName;
      {Displat name of snippet}
    property Category: string read fCategory;
      {Category to which snippet belongs}
    property Description: IActiveText read fDescription;
      {Description of snippet}
    property SourceCode: string read fSourceCode;
      {Source code of snippet}
    property HiliteSource: Boolean read fHiliteSource;
      {Flags whether source code can be syntax highlighted}
    property Extra: IActiveText read fExtra;
      {Additional information about snippet}
    property Compatibility: TCompileResults read fCompatibility;
      {Compiler compatibilty of this snippet}
    property TestInfo: TSnippetTestInfo read fTestInfo;
      {Describes level of testing carried out on snippet}
    property Units: TStringList read fUnits;
      {List of units used by snippet}
    property Depends: TSnippetList read fDepends;
      {List of any other snippet in database on which this snippet depends}
    property XRef: TSnippetList read fXRef;
      {List of cross referenced snippets in database}
    ///  <summary>ID of vault to which the snippet belongs.</summary>
    property CollectionID: TVaultID read fCollectionID;
  end;

  {
  TSnippetEx:
    Extension of TSnippet for use internally by Snippets object.
  }
  TSnippetEx = class(TSnippet)
  public
    procedure UpdateRefs(const Refs: TSnippetReferences;
      const AllSnippets: TSnippetList);
      {Updates a snippet's references.
        @param Refs [in] Stores all snippet's references (XRef, Depends and
          Units).
        @param AllSnippets [in] List of all snippets in database.
      }
    procedure Update(const Data: TSnippetEditData;
      const AllSnippets: TSnippetList);
      {Updates snippet's properties and references.
        @param Data [in] New property values and references.
        @param AllSnippets [in] List of all snippets in database.
      }
    function GetEditData: TSnippetEditData;
      {Gets details of all editable data of snippet.
        @return Required editable properties and references.
      }
    function GetProps: TSnippetData;
      {Gets details of snippet's properties.
        @return Record containing property values.
      }
    function GetReferences: TSnippetReferences;
      {Gets details of snippet's references.
        @return Information sufficient to define references.
      }
  end;

  {
  TTempSnippet:
    Special subclass of TSnippetEx that can't be added to the Snippets object.
    Class does nothing, simply provides a class name for testing when a snippet
    is added to a TSnippetListEx. TTempSnippet can be added to a normal snippet
    list.
  }
  TTempSnippet = class(TSnippetEx);

  {
  TSnippetList:
    Class that implements a list of TSnippet objects.
  }
  TSnippetList = class(TObject)
  strict private
    function GetItem(Idx: Integer): TSnippet;
      {Read accessor for Items property.
        @param Idx [in] Index of required snippet in list.
        @return Snippet at specified index in list.
      }

    ///  <summary>Finds a snippet in the list with whose key and collection ID
    ///  match.</summary>
    ///  <param name="SnippetKey"><c>string</c> [in] Snippet's key.</param>
    ///  <param name="ACollectionID"><c>TVaultID</c> [in] ID of vault to which
    ///  the snippet belongs.</param>
    ///  <param name="Index"><c>Integer</c>. [out] Set to the index of the
    ///  required snippet in the list. Valid only if the snippet was found.
    ///  </param>
    ///  <returns><c>Boolean</c>. True if snippet found, False if not.</returns>
    function Find(const SnippetKey: string; const ACollectionID: TVaultID;
      out Index: Integer): Boolean; overload;

  strict protected
    var fList: TSortedObjectList<TSnippet>; // Sorted list of snippets
  public
    constructor Create(const OwnsObjects: Boolean = False);
      {Constructor. Creates a new empty list.
        @param OwnsObjects [in] Specifies whether list owns the snippet objects
          it contains. If True the snippets are freed when deleted from list.
      }
    destructor Destroy; override;
      {Destructor. Tears down object.
      }
    procedure Assign(const SrcList: TSnippetList);
      {Sets this list to be same as another list. List items are referenced, not
      copied.
        @param SrcList [in] List of snippets to be assigned.
      }
    function IsEqual(const AList: TSnippetList): Boolean;
      {Checks if this list contains same snippets as another list.
        @param AList [in] List of snippets to compare.
        @return True if lists are same, False if not.
      }
    function Add(const Snippet: TSnippet): Integer; virtual;
      {Adds new snippet to the list, maintaining list in alphabetical order.
        @param Snippet [in] Snippet being added.
        @return Index where item was inserted in list
        @except Raised if duplicate snippet added to list.
      }
    function Find(const SnippetID: TSnippetID): TSnippet; overload;
      {Finds a specified snippet in list.
        @param SnippetID [in] ID of snippet to find.
        @return Reference to required snippet or nil if not found.
      }

    ///  <summary>Finds a snippet in the list with whose key and collection ID
    ///  match.</summary>
    ///  <param name="SnippetKey"><c>string</c> [in] Snippet's key.</param>
    ///  <param name="ACollectionID"><c>TVaultID</c> [in] ID of vault to which
    ///  the snippet belongs.</param>
    ///  <returns><c>TSnippet</c>. Reference to the required snippet or nil if
    ///  not found.</returns>
    function Find(const SnippetKey: string;
      const ACollectionID: TVaultID): TSnippet; overload;

    function Contains(const Snippet: TSnippet): Boolean;
      {Checks whether list contains a specified snippet.
        @param Snippet [in] Required snippet.
        @return True if snippet is in list, False otherwise.
      }
    function ContainsKinds(const Kinds: TSnippetKinds): Boolean;
      {Checks if the list contains specified kinds of snippets.
        @param Kinds [in] Set of kinds to test for.
        @return True if list contains at least one snippet of any of the
          specified kinds.
      }
    procedure Clear;
      {Clears the list.
      }
    function GetEnumerator: TEnumerator<TSnippet>;
      {Gets an intialised snippet list enumerator.
        @return Required enumerator.
      }

    ///  <summary>Counts number of snippets in list that belong to a specified
    ///  collection.</summary>
    ///  <param name="ACollectionID"><c>TVaultID</c> [in] Required vault.
    ///  </param>
    ///  <returns><c>Integer</c> Number of snippets in the collection.</returns>
    function Count(const ACollectionID: TVaultID): Integer; overload;

    function Count: Integer; overload;
      {Counts number of snippets in list.
        @return Number of snippets in list.
      }
    function IsEmpty: Boolean; overload; inline;
      {Checks if list is empty.
        @return True if list is empty, False otehrwise.
      }

    ///  <summary>Checks if the sub-set of snippets in the list belonging to a
    ///  specified collection is empty.</summary>
    ///  <param name="ACollectionID"><c>TVaultID</c> [in] ID of vault.</param>
    ///  <returns><c>Boolean</c> True if the subset is empty, False otherwise.
    ///  </returns>
    function IsEmpty(const ACollectionID: TVaultID): Boolean; overload;

    property Items[Idx: Integer]: TSnippet read GetItem; default;
      {List of snippets}
  end;

  {
  TSnippetListEx:
    Private extension of TSnippetList for use internally by Snippets object.
  }
  TSnippetListEx = class(TSnippetList)
  public
    function Add(const Snippet: TSnippet): Integer; override;
      {Adds a snippet to list. Snippet must not be TTempSnippet class.
        @param Snippet [in] Snippet to be added.
        @return Index where snippet was added to list.
      }
    procedure Delete(const Snippet: TSnippet);
      {Deletes a snippet from list.
        @param Snippet [in] Snippet to be deleted. No action taken if snippet
          not in list.
      }
  end;

  {
  TSnippetIDListEx:
    Extension of TSnippetIDList that provides an additional constructor that can
    create a snippet ID list from a TSnippetList.
  }
  TSnippetIDListEx = class(TSnippetIDList)
  public
    constructor Create(const SnipList: TSnippetList); overload;
      {Constructor overload that creates a snippets ID list from a
      TSnippetList object.
        @param SnipList [in] List of snippets objects for which ID list is
          required.
      }
  end;

implementation

uses
  // Delphi
  SysUtils,
  // Project
  IntfCommon, UExceptions, UStrUtils;

{ TSnippet }

function TSnippet.CanCompile: Boolean;
  {Checks if snippet can be compiled.
    @return True if compilation supported and False if not.
  }
begin
  Result := Kind <> skFreeform;
end;

function TSnippet.CompareTo(const Snippet: TSnippet): Integer;
begin
  Result := Self.ID.CompareTo(Snippet.ID);
end;

constructor TSnippet.Create(const AKey: string;
  const ACollectionID: TVaultID; const Props: TSnippetData);
begin
  Assert(ClassType <> TSnippet,
    ClassName + '.Create: must only be called from descendants.');
  Assert(not ACollectionID.IsNull,
    ClassName + '.Create: ACollectionID is null');
  inherited Create;
  // Record simple property values
  SetKey(AKey);
  SetProps(Props);
  // Create string list to store required units
  fUnits := TStringList.Create;
  // Create snippets lists for Depends and XRef properties
  fDepends := TSnippetListEx.Create;
  fXRef := TSnippetListEx.Create;
  // The following property added to support multiple snippet collections
  fCollectionID := ACollectionID.Clone;
end;

destructor TSnippet.Destroy;
  {Destructor. Tears down object.
  }
begin
  FreeAndNil(fXRef);
  FreeAndNil(fDepends);
  FreeAndNil(fUnits);
  fExtra := nil;
  fDescription := nil;
  inherited;
end;

function TSnippet.GetDisplayName: string;
begin
  if GetDisplayNameValue <> '' then
    Result := GetDisplayNameValue
  else
    Result := fKey;
end;

function TSnippet.GetDisplayNameValue: string;
begin
  Result := fDisplayName;
end;

function TSnippet.GetID: TSnippetID;
  {Gets snippet's unique ID.
    @return Required ID.
  }
begin
  Result := TSnippetID.Create(fKey, fCollectionID);
end;

function TSnippet.Hash: Integer;
begin
  // Snippet's hash code is the same as the snippet ID's hash code
  Result := GetID.Hash;
end;

function TSnippet.IsEqual(const Snippet: TSnippet): Boolean;
  {Checks if this snippet is same as another snippet. Snippets are considered
  equal if they have the same key and come from the same collection.
    @param Snippet [in] Snippet being compared.
    @return True if snippets are equal, False if not.
  }
begin
  Result := CompareTo(Snippet) = 0;
end;

procedure TSnippet.SetKey(const AKey: string);
begin
  fKey := StrTrim(AKey);
  Assert(fKey <> '', ClassName + '.SetKey: AKey is whitespace or empty');
end;

procedure TSnippet.SetProps(const Data: TSnippetData);
  {Sets snippet's properties.
    @param Data [in] Record containing property values.
  }
begin
  fCategory := Data.Cat;
  fKind := Data.Kind;
  fDescription := Data.Desc;
  fSourceCode := StrWindowsLineBreaks(Data.SourceCode);
  fHiliteSource := Data.HiliteSource;
  fDisplayName := Data.DisplayName;
  fExtra := TActiveTextFactory.CloneActiveText(Data.Extra);
  fCompatibility := Data.CompilerResults;
  fTestInfo := Data.TestInfo;
end;

{ TSnippet.TComparer }

function TSnippet.TComparer.Compare(const Left, Right: TSnippet): Integer;
begin
  Result := Left.CompareTo(Right);
end;

function TSnippet.TComparer.Equals(const Left, Right: TSnippet): Boolean;
begin
  Result := Left.IsEqual(Right);
end;

function TSnippet.TComparer.GetHashCode(const Value: TSnippet): Integer;
begin
  Result := Value.Hash;
end;

{ TSnippet.TDisplayNameComparer }

function TSnippet.TDisplayNameComparer.Compare(const Left,
  Right: TSnippet): Integer;
begin
  Result := StrCompareText(Left.DisplayName, Right.DisplayName);
  if Result = 0 then
    Result := Left.ID.CompareTo(Right.ID);
end;

{ TSnippetEx }

function TSnippetEx.GetEditData: TSnippetEditData;
  {Gets details of all editable data of snippet.
    @return Required editable properties and references.
  }
begin
  Result.Props := GetProps;
  Result.Refs := GetReferences;
end;

function TSnippetEx.GetProps: TSnippetData;
  {Gets details of snippet's properties.
    @return Record containing property values.
  }
begin
  Result.Cat := Category;
  Result.Kind := Kind;
  Result.Desc := Description;
  Result.SourceCode := SourceCode;
  Result.HiliteSource := HiliteSource;
  Result.DisplayName := GetDisplayNameValue;
  Result.Extra := TActiveTextFactory.CloneActiveText(Extra);
  Result.CompilerResults := Compatibility;
  Result.TestInfo := TestInfo;
end;

function TSnippetEx.GetReferences: TSnippetReferences;
  {Gets details of snippet's references.
    @return Information sufficient to define references.
  }
begin
  Result.Units := TIStringList.Create(Units);
  Result.Depends := TSnippetIDListEx.Create(Depends);
  Result.XRef := TSnippetIDListEx.Create(XRef);
end;

procedure TSnippetEx.Update(const Data: TSnippetEditData;
  const AllSnippets: TSnippetList);
  {Updates snippet's properties and references.
    @param Data [in] New property values and references.
    @param AllSnippets [in] List of all snippets in database.
  }
begin
  SetProps(Data.Props);
  UpdateRefs(Data.Refs, AllSnippets);
end;

procedure TSnippetEx.UpdateRefs(const Refs: TSnippetReferences;
  const AllSnippets: TSnippetList);
  {Updates a snippet's references.
    @param Refs [in] Stores all snippet's references (XRef, Depends and
      Units).
    @param AllSnippets [in] List of all snippets in database.
  }

  // ---------------------------------------------------------------------------
  procedure BuildSnippetList(const SL: TSnippetList;
    const IDList: ISnippetIDList);
    {Creates a snippets list from a snippets ID list. Looks up snippets in list
    of all snippets in database. Any snippets in ID list that do not exist in
    database are ignored.
      @param SL [in] Snippets list object to be updated.
      @param IDList [in] Snippets ID list that provides information used to
        create snippets list.
    }
  var
    ID: TSnippetID;     // refers to each ID in ID list
    Snippet: TSnippet;  // references each snippet identified by ID
  begin
    SL.Clear;
    for ID in IDList do
    begin
      Snippet := AllSnippets.Find(ID);
      if Assigned(Snippet) then
        SL.Add(Snippet);
    end;
  end;
  // ---------------------------------------------------------------------------

begin
  Refs.Units.CopyTo(Self.Units, True);            // copy units
  BuildSnippetList(Self.Depends, Refs.Depends);   // build Depends list
  BuildSnippetList(Self.XRef, Refs.XRef);         // build XRef list
end;

{ TSnippetList }

function TSnippetList.Add(const Snippet: TSnippet): Integer;
  {Adds new snippet to the list, maintaining list in alphabetical order.
    @param Snippet [in] Snippet being added.
    @return Index where item was inserted in list
    @except Raised if duplicate snippet added to list.
  }
begin
  Result := fList.Add(Snippet);
end;

procedure TSnippetList.Assign(const SrcList: TSnippetList);
  {Sets this list to be same as another list. List items are referenced, not
  copied.
    @param SrcList [in] List of snippets to be assigned.
  }
var
  Idx: Integer; // loops thru source list
begin
  Assert(not fList.OwnsObjects,
    ClassName + '.Assign: can''t assign to master list');
  Self.Clear;
  if Assigned(SrcList) then
  begin
    for Idx := 0 to Pred(SrcList.Count) do
      Self.Add(SrcList[Idx]);
  end;
end;

procedure TSnippetList.Clear;
  {Clears the list.
  }
begin
  fList.Clear;
end;

function TSnippetList.Contains(const Snippet: TSnippet): Boolean;
  {Checks whether list contains a specified snippet.
    @param Snippet [in] Required snippet.
    @return True if snippet is in list, False otherwise.
  }
begin
  Result := fList.Contains(Snippet);
end;

function TSnippetList.ContainsKinds(const Kinds: TSnippetKinds): Boolean;
  {Checks if the list contains specified kinds of snippets.
    @param Kinds [in] Set of kinds to test for.
    @return True if list contains at least one snippet of any of the specified
      kinds.
  }
var
  Snippet: TSnippet;  // reference to all snippets in list
begin
  Result := False;
  for Snippet in Self do
    if Snippet.Kind in Kinds then
    begin
      Result := True;
      Break;
    end;
end;

function TSnippetList.Count(const ACollectionID: TVaultID): Integer;
var
  Snippet: TSnippet;  // refers to all snippets in list
begin
  Result := 0;
  for Snippet in Self do
    if Snippet.CollectionID = ACollectionID then
      Inc(Result);
end;

function TSnippetList.Count: Integer;
  {Counts number of snippets in list.
    @return Number of snippets in list.
  }
begin
  Result := fList.Count;
end;

constructor TSnippetList.Create(const OwnsObjects: Boolean = False);
  {Constructor. Creates a new empty list.
    @param OwnsObjects [in] Specifies whether list owns the snippet objects it
      contains. If True the snippets are freed when deleted from list.
  }
begin
  inherited Create;
  fList := TSortedObjectList<TSnippet>.Create(
    TSnippet.TComparer.Create, OwnsObjects
  );
  fList.PermitDuplicates := False;
end;

destructor TSnippetList.Destroy;
  {Destructor. Tears down object.
  }
begin
  fList.Free; // destroys owned snippets if OwnsObjects=True
  inherited;
end;

function TSnippetList.Find(const SnippetKey: string;
  const ACollectionID: TVaultID; out Index: Integer): Boolean;
var
  TempSnippet: TSnippet;  // temp snippet used to perform search
  NullData: TSnippetData;  // nul data used to create snippet
begin
  // We need a temporary snippet object in order to perform binary search using
  // object list's built in search
  NullData.Init;
  TempSnippet := TTempSnippet.Create(SnippetKey, ACollectionID, NullData);
  try
    Result := fList.Find(TempSnippet, Index);
  finally
    TempSnippet.Free;
  end;
end;

function TSnippetList.Find(const SnippetKey: string;
  const ACollectionID: TVaultID): TSnippet;
var
  Idx: Integer; // index of snippet key in list
begin
  if Find(SnippetKey, ACollectionID, Idx) then
    Result := Items[Idx]
  else
    Result := nil;
end;

function TSnippetList.Find(const SnippetID: TSnippetID): TSnippet;
  {Finds a specified snippet in list.
    @param SnippetID [in] ID of snippet to find.
    @return Reference to required snippet or nil if not found.
  }
begin
  Result := Find(SnippetID.Key, SnippetID.CollectionID);
end;

function TSnippetList.GetEnumerator: TEnumerator<TSnippet>;
  {Gets an intialised snippet list enumerator.
    @return Required enumerator.
  }
begin
  Result := fList.GetEnumerator;
end;

function TSnippetList.GetItem(Idx: Integer): TSnippet;
  {Read accessor for Items property.
    @param Idx [in] Index of required snippet in list.
    @return Snippet at specified index in list.
  }
begin
  Result := fList[Idx];
end;

function TSnippetList.IsEmpty: Boolean;
  {Checks if list is empty.
    @return True if list is empty, False otehrwise.
  }
begin
  Result := Count = 0;
end;

function TSnippetList.IsEmpty(const ACollectionID: TVaultID): Boolean;
begin
  Result := Count(ACollectionID) = 0;
end;

function TSnippetList.IsEqual(const AList: TSnippetList): Boolean;
  {Checks if this list contains same snippets as another list.
    @param AList [in] List of snippets to compare.
    @return True if lists are same, False if not.
  }
var
  Idx: Integer; // loops thru all snippets in list
begin
  // To be same comparison list must exist and have same number of snippets
  Result := Assigned(AList) and (Self.Count = AList.Count);
  if Result then
  begin
    // Same number of snippets: scan list checking snippet keys are same. We can
    // rely on items being in same order since lists are sorted
    for Idx := 0 to Pred(Self.Count) do
    begin
      if not Self[Idx].IsEqual(AList[Idx]) then
      begin
        Result := False;
        Break;
      end;
    end;
  end;
end;

{ TSnippetListEx }

function TSnippetListEx.Add(const Snippet: TSnippet): Integer;
  {Adds a snippet to list. Snippet must not be TTempSnippet class.
    @param Snippet [in] Snippet to be added.
    @return Index where snippet was added to list.
  }
begin
  Assert(not(Snippet is TTempSnippet),
    ClassName + '.Add: Can''t add temporary snippets to database');
  Result := inherited Add(Snippet);
end;

procedure TSnippetListEx.Delete(const Snippet: TSnippet);
  {Deletes a snippet from list.
    @param Snippet [in] Snippet to be deleted. No action taken if snippet not in
      list.
  }
var
  Idx: Integer; // index of snippet in list.
begin
  Idx := fList.IndexOf(Snippet);
  if Idx = -1 then
    Exit;
  fList.Delete(Idx);  // this frees snippet if list owns objects
end;

{ TSnippetData }

procedure TSnippetData.Assign(const Src: TSnippetData);
  {Sets this record to be a copy of another record.
    @param Src [in] Record to be copied.
  }
begin
  Kind := Src.Kind;
  Cat := Src.Cat;
  Desc := TActiveTextFactory.CloneActiveText(Src.Desc);
  SourceCode := Src.SourceCode;
  HiliteSource := Src.HiliteSource;
  DisplayName := Src.DisplayName;
  // we use cloning for Extra below because it deals uccessfully with both
  // Self.Extra = nil and Src.Extra = nil
  Extra := TActiveTextFactory.CloneActiveText(Src.Extra);
  CompilerResults := Src.CompilerResults;
  TestInfo := Src.TestInfo;
end;

procedure TSnippetData.Init;
  {Initialises record by setting default values for fields.
  }
var
  CompID: TCompilerID;  // loops thru compiler IDs
begin
  Kind := skFreeform;
  Cat := '';
  Desc := TActiveTextFactory.CreateActiveText;
  DisplayName := '';
  SourceCode := '';
  HiliteSource := True;
  Extra := TActiveTextFactory.CreateActiveText;
  for CompID := Low(TCompilerID) to High(TCompilerID) do
    CompilerResults[CompID] := crQuery;
  TestInfo := stiNone;
end;

{ TSnippetReferences }

procedure TSnippetReferences.Assign(const Src: TSnippetReferences);
  {Sets this record to be a copy of another record.
    @param Src [in] Record to be copied.
  }
begin
  Init;
  (Units as IAssignable).Assign(Src.Units);
  (Depends as IAssignable).Assign(Src.Depends);
  (XRef as IAssignable).Assign(Src.XRef);
end;

procedure TSnippetReferences.Init;
  {Initialises record by creating objects stored in fields.
  }
begin
  Units := TIStringList.Create;
  Depends := TSnippetIDList.Create;
  XRef := TSnippetIDList.Create;
end;

{ TSnippetEditData }

procedure TSnippetEditData.Assign(const Src: TSnippetEditData);
  {Sets this record to be a copy of another record.
    @param Src [in] Record to be copied.
  }
begin
  Props.Assign(Src.Props);
  Refs.Assign(Src.Refs);
end;

procedure TSnippetEditData.Init;
  {Initialises record by creating default values and field objects.
  }
begin
  Props.Init;
  Refs.Init;
end;

{ TSnippetIDListEx }

constructor TSnippetIDListEx.Create(const SnipList: TSnippetList);
  {Constructor overload that creates a snippets ID list from a TSnippetList
  object.
    @param SnipList [in] List of snippets objects for which ID list is
      required.
  }
var
  Snippet: TSnippet;  // references each snippet in list
begin
  inherited Create;
  for Snippet in SnipList do
    Add(Snippet.ID);
end;

end.
