class DownloadsController < ApplicationController
  before_action :set_download, only: %i[show kill]

  # GET /downloads or /downloads.json
  def index
    @downloads = Download.order(created_at: :desc).page(params[:page])
  end

  # GET /downloads/1 or /downloads/1.json
  def show
  end

  # GET /downloads/new
  def new
    @download = Download.new
  end

  # POST /Download or /Download.json
  def create
    @download = Download.new(download_params)

    respond_to do |format|
      if @download.save
        format.html { redirect_to @download, notice: "Download is queued to run..." }
        format.json { render :show, status: :created, location: @download }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @download.errors, status: :unprocessable_entity }
      end
    end
  end

  def kill
    @download.kill!
    respond_to do |format|
      format.html { redirect_to downloads_path, notice: "Kill download sent." }
      format.json { render :show, status: :created, location: @download }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_download
    @download = Download.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def download_params
    params.require(:download).permit(:text)
  end
end
