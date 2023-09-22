defmodule Patchwork.Images do
  @mask_size 256
  @height 768

  def generate_image_and_mask(top_url, left_url) do
    top_image = fetch_image(top_url)
    left_image = fetch_image(left_url)

    {width, height} = {calc_width(top_url, left_url), calc_height(top_url, left_url)}

    base = Image.new!(width, height, color: :white)

    mask =
      gen_mask(top_image, left_image, base)
      |> Image.write!(:memory, suffix: ".png")
      |> binary_to_data_uri("image/png")

    image =
      gen_image(top_image, left_image, base)
      |> Image.write!(:memory, suffix: ".png")
      |> binary_to_data_uri("image/png")

    %{image: image, mask: mask, height: height, width: width}
  end

  def crop_bottom_right(image_url) do
    # Load the image
    image = fetch_image(image_url)

    # Calculate the x, y coordinates for cropping the bottom right portion
    {width, height} = {Image.width(image), Image.height(image)}
    x = width - @height
    y = height - @height

    # Crop the image starting at the calculated coordinates
    cropped_image = Image.crop!(image, x, y, 768, 768)

    # Write the cropped image to a buffer
    cropped_image |> Image.write!(:memory, suffix: ".png")
  end

  defp left_mask(), do: Image.Shape.rect!(@mask_size, @height, fill_color: "black", opacity: 1.0)
  defp top_mask(), do: Image.Shape.rect!(@height, @mask_size, fill_color: "black", opacity: 1.0)

  defp left_crop(image) do
    height = Image.height(image)
    width = Image.width(image)
    Image.crop!(image, width - @mask_size, @mask_size, @mask_size, height - @mask_size)
  end

  defp top_crop(image) do
    height = Image.height(image)
    width = Image.width(image)
    Image.crop!(image, @mask_size, height - @mask_size, width - @mask_size, @mask_size)
  end

  defp gen_image(image, nil, base) do
    height = Image.height(image)
    width = Image.width(image)

    top_crop = Image.crop!(image, 0, height - @mask_size, width, @mask_size)
    base |> Image.compose!(top_crop, x: 0, y: 0)
  end

  defp gen_image(nil, image, base) do
    height = Image.height(image)
    width = Image.width(image)

    left_crop = Image.crop!(image, width - @mask_size, 0, @mask_size, height)

    base |> Image.compose!(left_crop, x: 0, y: 0)
  end

  defp gen_image(top_image, left_image, base) do
    base
    |> Image.compose!(left_crop(left_image), x: 0, y: @mask_size)
    |> Image.compose!(top_crop(top_image), x: @mask_size, y: 0)
  end

  defp gen_mask(_top_image, nil, base) do
    base
    |> Image.compose!(top_mask(), x: 0, y: 0)
  end

  defp gen_mask(nil, _left_image, base) do
    base
    |> Image.compose!(left_mask(), x: 0, y: 0)
  end

  defp gen_mask(_top_image, _left_image, base) do
    base
    |> Image.compose!(left_mask(), x: 0, y: @mask_size)
    |> Image.compose!(top_mask(), x: @mask_size, y: 0)
  end

  defp fetch_image(nil), do: nil
  defp fetch_image(url), do: url |> Req.get!() |> Map.get(:body) |> Image.from_binary!()

  defp calc_height(nil, _left), do: @height
  defp calc_height(_top, _left), do: @height + @mask_size
  defp calc_width(_top, nil), do: @height
  defp calc_width(_top, _left), do: @height + @mask_size

  defp binary_to_data_uri(binary, mime_type) do
    base64 = Base.encode64(binary)
    "data:#{mime_type};base64,#{base64}"
  end

  def save_r2!(image_binary, uuid) do
    file_name = "prediction-#{uuid}.png"
    bucket = System.get_env("BUCKET_NAME")

    %{status_code: 200} =
      ExAws.S3.put_object(bucket, file_name, image_binary)
      |> ExAws.request!()

    "#{System.get_env("CLOUDFLARE_PUBLIC_URL")}/#{file_name}"
  end
end
