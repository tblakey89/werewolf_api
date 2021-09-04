defmodule WerewolfApi.Avatar do
  use Arc.Definition
  use Arc.Ecto.Definition
  alias WerewolfApi.User

  # ExAws.S3.list_buckets |> ExAws.request

  # get this working with local storage first, then do S3 later
  # read arc_ecto for guides on how to cast the image to object
  # don't need original

  @versions [:original, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 100x100^ -gravity center -extent 100x100 -format png", :png}
  end

  # Override the persisted filenames:
  def filename(version, {file, scope}) do
    "#{scope.id}__#{version}"
  end

  # Override the storage directory:
  # def storage_dir(version, {file, scope}) do
  #   "uploads/user/avatars/#{scope.id}"
  # end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end
end
