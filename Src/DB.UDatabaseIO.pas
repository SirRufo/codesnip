{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2008-2021, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Implements objects that can load data into the Database object from both the
 * user and main databases. Also provides a class that can write the user
 * database to storage.
 *
 * Uses file I/O interface implementations to read / write the physical files.
}


unit DB.UDatabaseIO;


interface


uses
  // Project
  DB.UCollections,
  DB.UCategory,
  DB.UMain,
  DB.USnippet,
  UBaseObjects,
  UExceptions;


type

  ///  <summary>Interface to objects that can load data into a collection within
  ///  the database from storage in a supported data format.</summary>
  IDataFormatLoader = interface(IInterface)
    ['{C6AF94FC-F56F-44AE-9E79-3B0CD0BB21D4}']
    ///  <summary>Loads data from storage into a collection within the database.
    ///  </summary>
    ///  <param name="SnipList"><c>TSnippetList</c> [in] Receives information
    ///  about each snippet in the collection.</param>
    ///  <param name="Categories"><c>TCategoryList</c> [in] Receives information
    ///  about each category in the collection.</param>
    ///  <param name="DBDataItemFactory"><c>DBDataItemFactory</c> [in] Object
    ///  used to create new categories and snippets.</param>
    procedure Load(const SnipList: TSnippetList;
      const Categories: TCategoryList;
      const DBDataItemFactory: IDBDataItemFactory);
  end;

  ///  <summary>Interface to objects that can save data from a collection within
  ///  the database into storage in a supported data format.</summary>
  IDataFormatSaver = interface(IInterface)
    ['{F46EE2E3-68A7-4877-9E04-192D15D29BB1}']
    ///  <summary>Saves data to storage.</summary>
    ///  <param name="SnipList"><c>TSnippetList</c> [in] Contains information
    ///  about each snippet to be saved.</param>
    ///  <param name="Categories"><c>TCategoryList</c> [in] Contains information
    ///  about each category to be saved.</param>
    ///  <param name="Provider"><c>IDBDataProvider</c> [in] Object used to
    ///  obtain details of the data to be stored.</param>
    procedure Save(const SnipList: TSnippetList;
      const Categories: TCategoryList; const Provider: IDBDataProvider);
  end;

  ///  <summary>Interface to object that can save global category information,
  ///  regardless of any categories saved with collections.</summary>
  IGlobalCategoryLoader = interface(IInterface)
    ['{0029F641-FAC4-43C8-A412-F70554BDCF28}']
     ///  <summary>Loads categories data from global storage.</summary>
    ///  <param name="Categories"><c>TCategoryList</c> [in] Receives information
    ///  about each category loaded.</param>
    ///  <param name="DBDataItemFactory"><c>IDBDataItemFactory</c> [in] Object
    ///  used to create new categories.</param>
   procedure Load(const Categories: TCategoryList;
      const DBDataItemFactory: IDBDataItemFactory);
  end;

  ///  <summary>Interface to object that can load global category information,
  ///  regardless of any categories loaded with collections.</summary>
  IGlobalCategorySaver = interface(IInterface)
    ['{D967E4FC-32FA-47F8-9BE0-4B25C7215CCA}']
    ///  <summary>Saves category data to global storage.</summary>
    ///  <param name="Categories"><c>TCategoryList</c> [in] Contains information
    ///  about each category to be saved.</param>
    procedure Save(const Categories: TCategoryList);
  end;

  {
  TDatabaseIOFactory:
    Factory class that can create instances of writer and loader objects for the
    Database object.
  }
  TDatabaseIOFactory = class(TNoConstructObject)
  public
    ///  <summary>Creates and returns an object to be used to load the given
    ///  collection's data in the correct format. Nil is returned if no loader
    ///  object is supported.</summary>
    class function CreateDBLoader(const Collection: TCollection):
      IDataFormatLoader;

    ///  <summary>Creates and returns an object to be used to save the given
    ///  collection's data in the correct format. Nil is return if no saver
    ///  object is supported.</summary>
    class function CreateDBSaver(const Collection: TCollection):
      IDataFormatSaver;

    ///  <summary>Creates and returns an object to be used to load a list of
    ///  globally stored categories.</summary>
    class function CreateGlobalCategoryLoader: IGlobalCategoryLoader;

    ///  <summary>Creates and returns an object to be used to save a list of
    ///  categories to global storage.</summary>
    class function CreateGlobalCategorySaver: IGlobalCategorySaver;

  end;

  {
  EDatabaseLoader:
    Class of exception raised by database loader objects.
  }
  EDatabaseLoader = class(ECodeSnip);


implementation


uses
  // Delphi
  SysUtils,
  Generics.Collections,
  IOUtils,
  // Project
  DBIO.UCategoryIO,
  DBIO.UFileIOIntf,
  DBIO.UIniData,
  DBIO.UNulDataReader,
  DBIO.UXMLDataIO,
  UAppInfo,
  UConsts,
  UIStringList,
  USnippetIDs,
  UUserDBBackup;


type

  {
  TDatabaseLoaderClass:
    Class reference to TDatabaseLoader descendants.
  }
  TDatabaseLoaderClass = class of TDatabaseLoader;

  {
  TDatabaseLoader:
    Abstract base class for objects that can load data into the Database object
    from storage.
  }
  TDatabaseLoader = class(TInterfacedObject, IDataFormatLoader)
  strict private
    fReader: IDataReader;         // Object used to read data from storage
    fSnipList: TSnippetList;      // Receives list of snippets
    fCategories: TCategoryList;   // Receives list of categories
    fFactory: IDBDataItemFactory; // Object creates new categories and snippets
    fCollection: TCollection;     // Collection being loaded
    procedure LoadSnippets(const Cat: TCategory);
      {Loads all snippets in a category.
        @param Cat [in] Category to be loaded.
      }
    procedure LoadReferences(const Snippet: TSnippet);
      {Loads all of a snippet's references.
        @param Snippet [in] Snippet for which references are required.
      }
    procedure HandleException(const E: Exception);
      {Handles exceptions generated by loader and converts ECodeSnip and
      descendant exceptions into EDatabaseLoader exceptions.
        @param E [in] Exception to be handled.
        @except Exception always raised.
      }
  strict protected
    function CreateReader: IDataReader; virtual; abstract;
      {Creates reader object for the database. If database doesn't exist a nul
      reader must be created.
        @return Reader object instance.
      }
    function FindSnippet(const SnippetKey: string;
      const SnipList: TSnippetList): TSnippet; virtual;
      {Finds the snippet object with a specified key.
        @param SnippetKey [in] Key of required snippet.
        @param SnipList [in] List of snippets to search.
        @return Reference to required snippet object or nil if snippet is not
          found.
      }
    function IsNativeSnippet(const Snippet: TSnippet): Boolean;
      virtual;
      {Checks if a snippet is native (belongs) to the database being read.
        @param Snippet [in] Snippet to test.
        @return True if snippet is native, False if not.
      }
    function ErrorMessageHeading: string; virtual; abstract;
      {Returns heading to use in error messages. Should identify the database.
        @return Required heading.
      }
    procedure LoadCategories;
      {Loads all categories from storage.
      }
    procedure CreateCategory(const CatID: string;
      const CatData: TCategoryData);
      {Creates a new category and adds it to the categories list.
        @param CatID [in] ID of category.
        @param CatData [in] Properties of category.
      }
    property Categories: TCategoryList read fCategories;
      {Reference to category list}
    property Collection: TCollection read fCollection;
  public
    constructor Create(const ACollection: TCollection);
    { IDataFormatLoader method }
    procedure Load(const SnipList: TSnippetList;
      const Categories: TCategoryList;
      const DBDataItemFactory: IDBDataItemFactory);
      {Loads data from storage and updates database object.
        @param SnipList [in] Receives information about each snippet in the
          database.
        @param Categories [in] Receives information about each category in the
          database.
        @param DBDataItemFactory [in] Object used to create new categories and
          snippets.
      }
  end;

  {
  TDCSCV2FormatLoader:
    Class that updates Database object with data read from main database.
  }
  TDCSCV2FormatLoader = class(TDatabaseLoader, IDataFormatLoader)
  strict protected
    function CreateReader: IDataReader; override;
      {Creates reader object. If main database doesn't exist a nul reader is
      created.
        @return Reader object instance.
      }
    function ErrorMessageHeading: string; override;
      {Returns heading to use in error messages. Identifies main database.
        @return Required heading.
      }
  end;

  {
  TNativeV4FormatLoader:
    Class that updates Database object with data read from user database.
  }
  TNativeV4FormatLoader = class(TDatabaseLoader, IDataFormatLoader)
  strict protected
    function CreateReader: IDataReader; override;
      {Creates reader object. If user database doesn't exist a nul reader is
      created.
        @return Reader object instance.
      }
    function ErrorMessageHeading: string; override;
      {Returns heading to use in error messages. Identifies main database.
        @return Required heading.
      }
  end;

  ///  <summary>Base for classes that save a collection to storage.</summary>
  TFormatSaver = class abstract (TInterfacedObject,
    IDataFormatSaver
  )
  strict private
    var
      fWriter: IDataWriter;             // Object used to write to storage
      fSnipList: TSnippetList;          // List of snippets to be written
      fCategories: TCategoryList;       // List of categories to be written
      fProvider: IDBDataProvider;       // Object used to get data to be written
      fCollection: TCollection;         // Collection being written

    ///  <summary>Writes information about all snippets belonging to the
    ///  collection.</summary>
    procedure WriteSnippets;

    ///  <summary>Writes information about categories relevant to the
    ///  collection.</summary>
    procedure WriteCategories;

  strict protected

    ///  <summary>Saves collection to storage.</summary>
    ///  <param name="SnipList"><c>TSnippetList</c> [in] List of all snippets
    ///  in the database.</param>
    ///  <param name="Categories"><c>TCategoryList</c> [in] List of all
    ///  categories in the database.</param>
    ///  <param name="Provider"><c>IDBDataProvider</c> [in] Object used to
    ///  obtain details of the data to be stored.</param>
    procedure DoSave(const SnipList: TSnippetList;
      const Categories: TCategoryList;
      const Provider: IDBDataProvider
    );

    ///  <summary>Creates an object that can write data to storage in the
    ///  required format.</summary>
    ///  <returns><c>IDataWriter</c>. Required writer object.</returns>
    function CreateWriter: IDataWriter; virtual; abstract;

    ///  <summary>Collection being saved.</summary>
    property Collection: TCollection read fCollection;

  public
    ///  <summary>Creates object that can save the given collection.</summary>
    constructor Create(const ACollection: TCollection);

    ///  <summary>Saves data to storage.</summary>
    ///  <param name="SnipList"><c>TSnippetList</c> [in] List of all snippets
    ///  in the database.</param>
    ///  <param name="Categories"><c>TCategoryList</c> [in] List of all
    ///  categories in the database.</param>
    ///  <param name="Provider"><c>IDBDataProvider</c> [in] Object used to
    ///  obtain details of the data to be stored.</param>
    ///  <remarks>Method of IDataFormatSaver.</remarks>
    procedure Save(const SnipList: TSnippetList;
      const Categories: TCategoryList;
      const Provider: IDBDataProvider); virtual; abstract;
  end;

  ///  <summary>Class used to write data from a collection to storage in the
  ///  DelphiDabbler Code Snippets v2 data format.</summary>
  TDCSCV2FormatSaver = class(TFormatSaver,
    IDataFormatSaver
  )
  strict private
    var
      fBakFile: string;                 // Backup file used in case of failure

    ///  <summary>Backup current data.</summary>
    procedure Backup;

    ///  <summary>Restore current data.</summary>
    procedure Restore;

  strict protected

    ///  <summary>Creates an object that can write data to storage in
    ///  DelphiDabbler Code Snippets v2 data format.</summary>
    ///  <returns><c>IDataWriter</c>. Required writer object.</returns>
    function CreateWriter: IDataWriter; override;

  public

    ///  <summary>Creates object that can save the given collection.</summary>
    constructor Create(const ACollection: TCollection);

    ///  <summary>Saves data to storage.</summary>
    ///  <param name="SnipList"><c>TSnippetList</c> [in] List of all snippets
    ///  in the database.</param>
    ///  <param name="Categories"><c>TCategoryList</c> [in] List of all
    ///  categories in the database.</param>
    ///  <param name="Provider"><c>IDBDataProvider</c> [in] Object used to
    ///  obtain details of the data to be stored.</param>
    ///  <remarks>Method of IDataFormatSaver.</remarks>
    procedure Save(const SnipList: TSnippetList;
      const Categories: TCategoryList;
      const Provider: IDBDataProvider); override;
  end;

  ///  <summary>Class used to write data from a collection to storage in
  ///  CodeSnip's native v4 data format.</summary>
  TNativeV4FormatSaver = class(TFormatSaver,
    IDataFormatSaver
  )
  strict protected

    ///  <summary>Creates an object that can write data to storage in
    ///  CodeSnip's native v4 data format.</summary>
    ///  <returns><c>IDataWriter</c>. Required writer object.</returns>
    function CreateWriter: IDataWriter; override;

  public

    ///  <summary>Saves data to storage.</summary>
    ///  <param name="SnipList"><c>TSnippetList</c> [in] List of all snippets
    ///  in the database.</param>
    ///  <param name="Categories"><c>TCategoryList</c> [in] List of all
    ///  categories in the database.</param>
    ///  <param name="Provider"><c>IDBDataProvider</c> [in] Object used to
    ///  obtain details of the data to be stored.</param>
    ///  <remarks>Method of IDataFormatSaver.</remarks>
    procedure Save(const SnipList: TSnippetList;
      const Categories: TCategoryList;
      const Provider: IDBDataProvider); override;
  end;

  ///  <summary>Class used to save global category information, regardless of
  ///  any categories saved with collections.</summary>
  TGlobalCategoryLoader = class(TInterfacedObject, IGlobalCategoryLoader)
  public
    ///  <summary>Loads categories data from global storage.</summary>
    ///  <param name="Categories"><c>TCategoryList</c> [in] Receives information
    ///  about each category loaded.</param>
    ///  <param name="DBDataItemFactory"><c>IDBDataItemFactory</c> [in] Object
    ///  used to create new categories.</param>
    ///  <remarks>Method of <c>IGlobalCategoryLoader</c>.</remarks>
    procedure Load(const Categories: TCategoryList;
      const DBDataItemFactory: IDBDataItemFactory);
  end;

  ///  <summary>Class used to save global category information, regardless of
  ///  any categories saved with collections.</summary>
  TGlobalCategorySaver = class(TInterfacedObject, IGlobalCategorySaver)
  public
    ///  <summary>Saves category data to global storage.</summary>
    ///  <param name="Categories"><c>TCategoryList</c> [in] Contains information
    ///  about each category to be saved.</param>
    ///  <remarks>Method of <c>IGlobalCategorySaver</c>.</remarks>
    procedure Save(const Categories: TCategoryList);
  end;

{ TDatabaseIOFactory }

class function TDatabaseIOFactory.CreateDBLoader(const Collection: TCollection):
  IDataFormatLoader;
begin
  {TODO -cUDatabaseIO: Revise database loaders to get file path and other
          info from collection instead of hard wiring it.}
  case Collection.CollectionFormatKind of
    TCollectionFormatKind.DCSC_v2:
      Result := TDCSCV2FormatLoader.Create(Collection);
    TCollectionFormatKind.Native_v4:
      Result := TNativeV4FormatLoader.Create(Collection);
    else
      Result := nil;
  end;
end;

class function TDatabaseIOFactory.CreateDBSaver(
  const Collection: TCollection): IDataFormatSaver;
begin
  case Collection.CollectionFormatKind of
    TCollectionFormatKind.DCSC_v2:
      Result := TDCSCV2FormatSaver.Create(Collection);
    TCollectionFormatKind.Native_v4:
      Result := TNativeV4FormatSaver.Create(Collection);
    else
      Result := nil;
  end;
end;

class function TDatabaseIOFactory.CreateGlobalCategoryLoader:
  IGlobalCategoryLoader;
begin
  Result := TGlobalCategoryLoader.Create;
end;

class function TDatabaseIOFactory.CreateGlobalCategorySaver:
  IGlobalCategorySaver;
begin
  Result := TGlobalCategorySaver.Create;
end;

{ TDatabaseLoader }

constructor TDatabaseLoader.Create(const ACollection: TCollection);
begin
  inherited Create;
  fCollection := ACollection;
end;

procedure TDatabaseLoader.CreateCategory(const CatID: string;
  const CatData: TCategoryData);
  {Creates a new category and adds it to the categories list.
    @param CatID [in] ID of category.
    @param CatData [in] Properties of category.
  }
begin
  fCategories.Add(fFactory.CreateCategory(CatID, CatData));
end;

function TDatabaseLoader.FindSnippet(const SnippetKey: string;
  const SnipList: TSnippetList): TSnippet;
begin
  Result := SnipList.Find(SnippetKey, Collection.UID);
end;

procedure TDatabaseLoader.HandleException(const E: Exception);
  {Handles exceptions generated by loader and converts ECodeSnip and descendant
  exceptions into EDatabaseLoader exceptions.
    @param E [in] Exception to be handled.
    @except Exception always raised.
  }
begin
  if E is ECodeSnip then
    // add message header identifying database to existing message
    raise EDatabaseLoader.Create(ErrorMessageHeading + EOL2 + E.Message)
  else
    raise E;
end;

function TDatabaseLoader.IsNativeSnippet(const Snippet: TSnippet): Boolean;
begin
  Result := Snippet.CollectionID = Collection.UID;
end;

procedure TDatabaseLoader.Load(const SnipList: TSnippetList;
  const Categories: TCategoryList; const DBDataItemFactory: IDBDataItemFactory);
  {Loads data from storage and updates database object.
    @param SnipList [in] Receives information about each snippet in the
      database.
    @param Categories [in] Receives information about each category in the
      database.
    @param DBDataItemFactory [in] Object used to create new categories and
      snippets.
  }
var
  Category: TCategory;  // a category
  Snippet: TSnippet;    // a snippet
begin
  // Create reader object that can access data storage
  fReader := CreateReader;
  // Record snippets and categories list in fields
  // Do not clear snippet or category lists: may already contain data
  fSnipList := SnipList;
  fCategories := Categories;
  fFactory := DBDataItemFactory;
  try
    // Load categories
    LoadCategories;
    // Load snippets in each category
    for Category in fCategories do
      LoadSnippets(Category);
    // Build XRef, Depends and Units reference list of each snippet for this
    // database
    for Snippet in fSnipList do
    begin
      if IsNativeSnippet(Snippet) then
        LoadReferences(Snippet);
    end;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

procedure TDatabaseLoader.LoadCategories;
  {Loads all categories from storage
  }
var
  CatIDs: IStringList;      // list of ids of categories
  CatID: string;            // name of each category
  Category: TCategory;      // a category object
  CatData: TCategoryData;   // properties of a category
begin
  // Get name of all categories
  CatIDs := fReader.GetAllCatIDs;
  // Loop through each category by name
  for CatID in CatIDs do
  begin
    // Check if category exists, creating it if not
    Category := fCategories.Find(CatID);
    if not Assigned(Category) then
    begin
      fReader.GetCatProps(CatID, CatData);
      CreateCategory(CatID, CatData);
    end;
  end;
end;

procedure TDatabaseLoader.LoadReferences(const Snippet: TSnippet);
  {Loads all of a snippet's references.
    @param Snippet [in] Snippet for which references are required.
  }

  // ---------------------------------------------------------------------------
  procedure LoadSnippetReferences(const RefList: TSnippetList;
    const RefKeys: IStringList);
    {Creates a snippet list from keys of snippets in a string list. If no
    snippet with a given key is found no matching entry is added to snippet
    list.
      @param RefList [in] List to receive referenced snippets.
      @param RefKeys [in] List of snippet keys.
    }
  var
    RefKey: string;         // referenced snippet key
    Reference: TSnippet;    // referenced snippet object
  begin
    for RefKey in RefKeys do
    begin
      Reference := FindSnippet(RefKey, fSnipList);
      if Assigned(Reference) then
        RefList.Add(Reference);
    end;
  end;
  // ---------------------------------------------------------------------------

begin
  LoadSnippetReferences(
    Snippet.Depends, fReader.GetSnippetDepends(Snippet.Key)
  );
  LoadSnippetReferences(
    Snippet.XRef, fReader.GetSnippetXRefs(Snippet.Key)
  );
  fReader.GetSnippetUnits(Snippet.Key).CopyTo(Snippet.Units);
end;

procedure TDatabaseLoader.LoadSnippets(const Cat: TCategory);
  {Loads all snippets in a category.
    @param Cat [in] Category to be loaded.
  }
var
  SnippetKeys: IStringList;     // list of keys of snippets in category
  SnippetProps: TSnippetData;   // properties of a snippet
  SnippetKey: string;           // each key in key list
  Snippet: TSnippet;            // references a snippet object
begin
  FillChar(SnippetProps, SizeOf(SnippetProps), 0);
  // Get keys of all snippets in category
  SnippetKeys := fReader.GetCatSnippets(Cat.ID);
  // Process each snippet key in list
  for SnippetKey in SnippetKeys do
  begin
    // Check if snippet exists in current database and add it to list if not
    Snippet := fSnipList.Find(SnippetKey, Collection.UID);
    if not Assigned(Snippet) then
    begin
      fReader.GetSnippetProps(SnippetKey, SnippetProps);
      Snippet := fFactory.CreateSnippet(
        SnippetKey, Collection.UID, SnippetProps
      );
      fSnipList.Add(Snippet);
    end;
    // Add snippet to database only if it belongs to this database
    if IsNativeSnippet(Snippet) then
      Cat.Snippets.Add(Snippet);
  end;
end;

{ TDCSCV2FormatLoader }

function TDCSCV2FormatLoader.CreateReader: IDataReader;
  {Creates reader object. If main database doesn't exist a nul reader is
  created.
    @return Reader object instance.
  }
begin
  Result := TIniDataReader.Create(Collection.Location.Directory);
  if not Result.DatabaseExists then
    Result := TNulDataReader.Create;
end;

function TDCSCV2FormatLoader.ErrorMessageHeading: string;
  {Returns heading to use in error messages. Identifies main database.
    @return Required heading.
  }
resourcestring
  sError = 'Error loading the CodeSnip database:';
begin
  Result := sError;
end;

{ TNativeV4FormatLoader }

function TNativeV4FormatLoader.CreateReader: IDataReader;
  {Creates reader object. If user database doesn't exist a nul reader is
  created.
    @return Reader object instance.
  }
begin
  Result := TXMLDataReader.Create(Collection.Location.Directory);
  if not Result.DatabaseExists then
    Result := TNulDataReader.Create;
end;

function TNativeV4FormatLoader.ErrorMessageHeading: string;
  {Returns heading to use in error messages. Identifies main database.
    @return Required heading.
  }
resourcestring
  sError = 'Error loading the user defined database:';
begin
  Result := sError;
end;

{ TFormatSaver }

constructor TFormatSaver.Create(const ACollection: TCollection);
begin
  inherited Create;
  fCollection := ACollection;
end;

procedure TFormatSaver.DoSave(const SnipList: TSnippetList;
  const Categories: TCategoryList; const Provider: IDBDataProvider);
begin
  fSnipList := SnipList;
  fCategories := Categories;
  fProvider := Provider;
  fWriter := CreateWriter;
  fWriter.Initialise;
  WriteCategories;
  WriteSnippets;
  fWriter.Finalise;
end;

procedure TFormatSaver.WriteCategories;
var
  Cat: TCategory;         // loops through each category
  Props: TCategoryData;   // category properties
  SnipList: IStringList;  // list of keys of snippets in a category
begin
  for Cat in fCategories do
  begin
    SnipList := fProvider.GetCategorySnippets(Cat);
    // only write category info when not empty
    if SnipList.Count > 0 then
    begin
      Props := fProvider.GetCategoryProps(Cat);
      fWriter.WriteCatProps(Cat.ID, Props);
      fWriter.WriteCatSnippets(Cat.ID, SnipList);
    end;
  end;
end;

procedure TFormatSaver.WriteSnippets;

  // Adds snippet keys from IDList to a string list
  function IDListToStrings(const IDList: ISnippetIDList): IStringList;
  var
    ID: TSnippetID; // each id in snippet id list
  begin
    Result := TIStringList.Create;
    for ID in IDList do
      Result.Add(ID.Key);
  end;

var
  Snippet: TSnippet;        // loops through each snippet in list
  Props: TSnippetData;      // snippet properties
  Refs: TSnippetReferences; // snippet references
begin
  for Snippet in fSnipList do
  begin
    if Snippet.CollectionID = fCollection.UID then
    begin
      // Get and write a snippet's properties
      Props := fProvider.GetSnippetProps(Snippet);
      fWriter.WriteSnippetProps(Snippet.Key, Props);
      // Get and write a snippet's references
      Refs := fProvider.GetSnippetRefs(Snippet);
      fWriter.WriteSnippetUnits(Snippet.Key, Refs.Units);
      fWriter.WriteSnippetDepends(Snippet.Key, IDListToStrings(Refs.Depends));
      fWriter.WriteSnippetXRefs(Snippet.Key, IDListToStrings(Refs.XRef));
    end;
  end;
end;

{ TDCSCV2FormatSaver }

procedure TDCSCV2FormatSaver.Backup;
var
  FB: TUserDBBackup;  // TODO -cRefactoring: this is correct class (will change)
begin
  FB := TUserDBBackup.Create(fBakFile, Collection);
  try
    FB.Backup;
  finally
    FB.Free;
  end;
end;

constructor TDCSCV2FormatSaver.Create(const ACollection: TCollection);
begin
  inherited Create(ACollection);
  // Find a temp file name in system temp directory that doesn't yet exist
  repeat
    fBakFile := TPath.Combine(
      TPath.GetTempPath, '~codesnip-' + TPath.GetGUIDFileName
    );
  until not TFile.Exists(fBakFile);
end;

function TDCSCV2FormatSaver.CreateWriter: IDataWriter;
begin
  Result := TIniDataWriter.Create(Collection.Location.Directory);
end;

procedure TDCSCV2FormatSaver.Restore;
var
  FB: TUserDBBackup;
begin
  FB := TUserDBBackup.Create(fBakFile, Collection);
  try
    FB.Restore;
  finally
    FB.Free;
  end;
end;

procedure TDCSCV2FormatSaver.Save(const SnipList: TSnippetList;
  const Categories: TCategoryList; const Provider: IDBDataProvider);
begin
  Backup;
  try
    try
      DoSave(SnipList, Categories, Provider);
    except
      Restore;
      raise ExceptObject;
    end;
  finally
    TFile.Delete(fBakFile);
  end;
end;

{ TNativeV4FormatSaver }

function TNativeV4FormatSaver.CreateWriter: IDataWriter;
begin
  Result := TXMLDataWriter.Create(Collection.Location.Directory);
end;

procedure TNativeV4FormatSaver.Save(const SnipList: TSnippetList;
  const Categories: TCategoryList; const Provider: IDBDataProvider);
begin
  DoSave(SnipList, Categories, Provider);
end;

{ TGlobalCategoryLoader }

procedure TGlobalCategoryLoader.Load(const Categories: TCategoryList;
  const DBDataItemFactory: IDBDataItemFactory);
var
  Reader: TCategoryReader;
  CatInfo: TCategoryReader.TCategoryIDAndData;
  Cat: TCategory;
begin
  if not TFile.Exists(TAppInfo.UserCategoriesFileName) then
    Exit;
  Reader := TCategoryReader.Create(TAppInfo.UserCategoriesFileName);
  try
    for CatInfo in Reader.Read do
    begin
      Cat := Categories.Find(CatInfo.Key);
      if not Assigned(Cat) then
      begin
        Categories.Add(
          DBDataItemFactory.CreateCategory(CatInfo.Key, CatInfo.Value)
        )
      end
      else
      begin
        if Cat.Description <> CatInfo.Value.Desc then
          Cat.Update(CatInfo.Value);
      end;
    end;
  finally
    Reader.Free;
  end;
end;

{ TGlobalCategorySaver }

procedure TGlobalCategorySaver.Save(const Categories: TCategoryList);
var
  Writer: TCategoryWriter;
begin
  Writer := TCategoryWriter.Create(TAppInfo.UserCategoriesFileName);
  try
    Writer.Write(Categories);
  finally
    Writer.Free;
  end;
end;

end.

